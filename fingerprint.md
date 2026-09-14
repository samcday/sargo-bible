# Fingerprint — Google Pixel 3a (`google/sargo`)

**Status.** The sargo fingerprint stack is understood end to end: hardware
wiring, the split between normal world and secure world, the trusted
application's command interface, and the authorization chain that gates
enrollment. The proof is an independent Linux implementation that enrolls and
matches fingers on real hardware (§8). Evidence classes are defined in
[CLANKER-README.md](CLANKER-README.md); the stock build, kernel commit and
binary hashes referenced below are pinned in [provenance.md](provenance.md).

Shorthand: `TA` = QSEE trusted application, `HAL` = the stock Android
fingerprint service, `HAT` = hardware authentication token.

## 1. Hardware

| Fact | Value | Evidence |
| --- | --- | --- |
| Sensor family | FPC1020-class touch sensor, rear mounted | `[G]` DT compatible `fpc,fpc1020` in [`sdm670-b4s4-fingerprint.dtsi`](https://android.googlesource.com/kernel/msm/+/ab4493f31457eea175568b18b8300d4d12aaeea8/arch/arm64/boot/dts/google/sdm670-b4s4-fingerprint.dtsi) (vendored copy: [`vendor/`](vendor/kernel-msm-ab4493f31457eea175568b18b8300d4d12aaeea8/arch/arm64/boot/dts/google/sdm670-b4s4-fingerprint.dtsi)) |
| Interrupt line | TLMM GPIO 121, input, `bias-pull-down`, drive strength 2, rising edge | `[G]` same dtsi; driver requests `IRQF_TRIGGER_RISING \| IRQF_ONESHOT` |
| Reset line | TLMM GPIO 134, output, `bias-disable`; pinctrl states `fpc_reset_low` / `fpc_reset_high` | `[G]` same dtsi |
| Node is in the shipped DT | `fp_fpc1020` with the same two GPIOs appears in every sargo (`S4`) overlay inside Google's `dtbo.img` for build SP2A.220505.008 | `[G]` factory image, `dtbo.img` entries 1/3/5/7/9 (`model = "Google Inc. MSM sdm670 S4 …"`, `compatible = "google,b4s4-sdm670"`) |
| No Linux-visible sensor bus | The DT declares no SPI/I2C child for the sensor. On a running sargo the only SPI device is `spi0.0` (`rt5514` audio) | `[G]` DT; `[M]` daily unit, 2026-09-10 |
| Regulators | None declared for the sensor in the sargo DT; the driver's optional regulator lookups are unused | `[G]` dtsi vs driver `vreg_conf` table |
| Part revision | Not measured. `fpc,fpc1020` names the driver family, not a die step | open, §10 |

Node as written in the source dtsi; the decompiled `S4 PVT` overlay from Google's `dtbo.img` carries the same values (`interrupts = <0x79 0x00>`, reset `0x86`, IRQ `0x79`):

```dts
fp_fpc1020 {
        status = "ok";
        compatible = "fpc,fpc1020";
        interrupt-parent = <&tlmm>;
        interrupts = <121 0x0>;
        fpc,gpio_rst = <&tlmm 134 0x0>;
        fpc,gpio_irq = <&tlmm 121 0x0>;
        pinctrl-names = "fpc1020_reset_reset", "fpc1020_reset_active", "fpc1020_irq_active";
        pinctrl-0 = <&fpc_reset_low>;
        pinctrl-1 = <&fpc_reset_high>;
        pinctrl-2 = <&fpc_irq_default>;
};
```

The sensor's SPI bus is owned by the secure world. Normal-world Linux controls
only reset and observes only the interrupt.

## 2. Stock software split

Who does what in build SP2A.220505.008. Hashes are in provenance.md §5.

| Component | Where | Role | Evidence |
| --- | --- | --- | --- |
| `fpc1020_platform_tee.c` | kernel, `CONFIG_FPC_FINGERPRINT=y` in `bonito_defconfig` | Electrical control only: reset, IRQ, wakeup. Exposes sysfs `hw_reset`, `wakeup_enable`, `irq` (read = level, write = ack), `regulator_enable`, `device_prepare`, `pinctl_set`, `clk_enable` (stub). Threaded rising-edge IRQ; wakeup source `fpc_ttw_ws`. Header comment: "This driver will NOT send any commands to the sensor" | `[G]` [driver source](https://android.googlesource.com/kernel/msm/+/ab4493f31457eea175568b18b8300d4d12aaeea8/drivers/input/misc/fpc_fingerprint/fpc1020_platform_tee.c) |
| `qseecom` | kernel, `CONFIG_QSEECOM=y`; `/dev/qseecom` | Loads TAs and common libraries into QSEE, routes commands, hosts listener callbacks | `[G]` [`qseecom.h`](https://android.googlesource.com/kernel/msm/+/ab4493f31457eea175568b18b8300d4d12aaeea8/include/uapi/linux/qseecom.h), [`qseecomi.h`](https://android.googlesource.com/kernel/msm/+/ab4493f31457eea175568b18b8300d4d12aaeea8/include/soc/qcom/qseecomi.h) |
| `qseecomd` | `/vendor/bin/qseecomd` | Registers the machine-wide listener services (filesystem, RPMB, …) that TAs call back into | `[S]` present in vendor image |
| `libQSEEComAPI.so` | `/vendor/lib64` | Userspace wrapper over `/dev/qseecom` ioctls | `[S]` |
| `android.hardware.biometrics.fingerprint@2.1-service.fpc` | `/vendor/bin/hw` | The HAL: drives the kernel sysfs nodes and sends every TA command. Links `libQSEEComAPI.so`, `com.fingerprints.extension@1.0.so`, HIDL fingerprint 2.1/2.2 | `[S]` ELF `DT_NEEDED` |
| `fpctzappfingerprint` | `/vendor/firmware/*.mdt,*.b00–b07` | The TA: sensor control over secure SPI, image capture, template matching, enrollment authorization | `[S]` |
| `cmnlib64` | `/vendor/firmware/cmnlib64.*` and fixed partitions `cmnlib64_a/b` | QSEE common library the TA links (`DT_NEEDED libcmnlib.so`); ELF64 class selects `cmnlib64`, not `cmnlib` | `[S]`, `[G]` bootloader package |
| `keymaster64` | fixed partitions `keymaster_a/b` (loaded by the bootloader, not by Android) | Keymaster **and** Gatekeeper live in this one TA. Issues the wrapped HAT-signing key to FPC; signs HATs on credential verification | `[S]` §5 |
| RPMB | eMMC RPMB region, 16 MiB, enhanced RPMB | Gatekeeper's credential table; reached through the RPMB listener | `[M]` eMMC capability metadata |

## 3. QSEE and application loading

| Fact | Value | Evidence |
| --- | --- | --- |
| QSEE version | `0x1400000` | `[M]` reported at boot on both units. ≥ `QSEE_VERSION_40` (`0x1000000`), so the kernel uses the 64-bit request structs |
| Secure-app region | `qseecom@86d00000`, `reg = <0x86d00000 0x2200000>`, `qcom,appsbl-qseecom-support`, `qcom,qsee-reentrancy-support = <2>` | `[G]` `sdm670.dtsi`; present in the shipped base DTB |
| Reserved memory | `qseecom_region@0x9e400000`, 20 MiB, `no-map`; `qseecom_ta_region`, 16 MiB reusable CMA, 4 MiB alignment | `[G]` `sdm670.dtsi`; `[M]` `qseecom@9e400000` visible on a running unit |
| App start | `QSEOS_APP_START_COMMAND = 0x01`; request `{cmd, mdt_len, img_len, phy_addr (u64), app_name[64]}` (`struct qseecom_load_app_64bit_ireq`) | `[G]` `qseecomi.h` |
| Common library load | `QSEOS_LOAD_SERV_IMAGE_COMMAND` (same request shape, no app name); the library stays resident for the boot | `[G]` `qseecomi.h`; `[M]` |
| Image assembly | The TA ships split: `.mdt` = ELF header + hash segment (`b00` + `b01`, byte-identical to their concatenation), then one `.bNN` per program header. The loader lays segments contiguously at `p_paddr`-relative offsets in DMA-coherent memory and passes one physical address | `[S]` manifest structure; `[G]` `qseecom.c` load path |
| TA image | ELF64 AArch64 (`e_machine` 183), 8 program headers, **zero section headers**, but `PT_DYNAMIC` carries 1101 dynamic symbols and relocations. Segment sizes 512, 6696, 522392, 165, 57576, 720, 304, 85332 | `[S]`, `[G]` same bytes in Google's `vendor.img` |
| `cmnlib64` image | ELF64 AArch64, 6 program headers; segments 400, 6632, 436992, 4240, 288, 30371 | `[S]`, `[G]` |
| Listener services | Kernel reserves `RPMB_SERVICE = 0x2000` and `SSD_SERVICE = 0x3000`. Registered at runtime by the stock daemon: FS `0xa` (10), GPFS `0x7000` (28672), RPMB `0x2000` | `[G]` `qseecom.c`; `[M]` all three registered from Linux on both units |
| One receiver per machine | Listener registration is machine-wide; a second independent receiver process is not accepted by the kernel interface | `[M]` |

## 4. TA command interface

Recovered from the TA's dynamic symbols and the HAL's call sites `[S]`, then
exercised on hardware `[M]`. Offsets are byte offsets inside the auxiliary
buffer unless stated. All integers little-endian.

### 4.1 Transport

| Fact | Value |
| --- | --- |
| Session | HAL opens `fpctzappfingerprint` with a 128-byte primary shared buffer and an ION auxiliary buffer rounded to 4096 bytes |
| Primary request | 64 bytes: `u32 aux_len` at 0, **unaligned** `u64 aux_phys` at 4, zero padding to 64. Response 64 bytes; first word is the dispatcher status |
| HAL API | `QSEECom_send_modified_cmd` (32-bit patch at offset 4). The TA reads the full 64-bit field, so stock relies on a sub-4 GiB allocation with a zero high word. A native client may patch all 64 bits |
| TA wrapper limits | request ≥ 12 bytes, response ≥ 4 bytes, aux ≤ 1 MiB (`0x46e8` in the TA) |
| Aux layout | `u32 target` at 0, `u32 command` at 4, `i32 command_result` at 8, payload from 12 |
| Two statuses | Dispatcher status (primary response word 0) and command result (aux offset 8) are independent; interpret payload only when both are 0 |
| Module registry | seven targets: 12 common, 11 biometrics, 10 sensor, 9 KPI, 8 navigation, 3 hardware authentication, 2 files |

### 4.2 Target 10 — sensor

Handler needs ≥ 84 bytes; stock uses 88 (`0x58`). Result at 8, capture detail at 12.

| Cmd | Name | Notes |
| ---: | --- | --- |
| 0 | init | `fpc_device_init`; 0 = success |
| 1 | check_finger_lost | returns 0/1; stock capture ignores it |
| 2 | finger_lost_wakeup_setup | arm IRQ for finger release |
| 3 | wakeup_setup | arm IRQ for finger contact |
| 4 | qualify_capture | 0 = a qualified image is held for target 11 |
| 5 | deep_sleep | 0 = success |
| 6 | otp_supported | query |
| 7 | otp_info | query; payload not decoded |

Stock capture sequence (HAL `0xb488`): enable kernel IRQ wake → cmd 2, wait for
IRQ level 1, cmd 1 → cmd 3, wait for IRQ level 1, cmd 4 → on success disable
wake and hand the image to target 11; on failure or cancel, disable wake and
cmd 5. The IRQ waiter reads the GPIO level first, waits on the IRQ and a cancel
pipe, acknowledges via sysfs, rereads the level. **An IRQ is a wake signal,
never a capture or match result.**

Capture results: `0x107` retry up to four times quickly (a wait > 500 ms
resets the counter), then report "insufficient"; `0x105` = too fast,
recapture; `0x108` silently recaptured in the enrollment loop; `-206` = general
communication failure; `-212` = hardware error.

### 4.3 Target 11 — biometrics

Handler needs 40 bytes; offset 12 is the principal in/out word, 16–39 six more
words. Command table at TA `0x45eb4`. Database holds at most 5 templates.

| Cmd | Name | Payload |
| ---: | --- | --- |
| 0 | begin_enrol | — |
| 1 | enrol | out: remaining samples at 12 |
| 2 | end_enrol | out: new template id at 12; **requires a valid enrollment authorization (§5)** |
| 3 | identify | out: template id at 12, decision at 28 |
| 4 | update_template | out: updated boolean at 12; must follow every identify |
| 5 | (unsupported) | do not issue |
| 6 | load_empty_db | destroys the in-memory database |
| 7 | get_template_ids | in: capacity at 12; out: count at 12, ids from 16 |
| 8 | delete_template | in: nonzero id at 12; id 0 → `-210` |
| 9 | set_active_set | in: group id at 12 |
| 10 | get_db_id | out: u64 at 16 |

Enrollment loop results for cmd 1: `0` complete (issue cmd 2 now), `0x10f`
progress, `0x110` unable to process (terminate), `0x111` vendor error 1000
(terminate), `0x112` partial (retry), `0x113` progress + vendor acquisition
1000, `0x114` dirty image (retry). The initial sample count is not a constant.

A match is **only** transport 0 ∧ dispatcher 0 ∧ command 0 ∧ template id ≠ 0 ∧
decision = 1. Command success alone includes non-matches. After every identify,
match or not, stock issues cmd 4 (`fpc_algo_identify_update` +
`fpc_algo_end_identify`) and stores the database only if the update boolean is
set. Skipping cmd 4 leaves the algorithm in state 2; the next identify fails
with `-211` (TA maps algorithm error `-115` to it). `[M]` observed on the lab
unit.

### 4.4 Target 2 — files

Cmd 11 load, cmd 12 store. Offset 12 = path length including NUL, path from 16.
Load destroys the in-memory database before reading, so a failed load does not
preserve the previous one. The TA's file I/O goes through the QSEE storage
listeners (§3), so a listener must be registered before any load/store.

### 4.5 Target 3 — hardware authentication

Handler needs ≥ 24 bytes; results at 8.

| Cmd | Name | Payload |
| ---: | --- | --- |
| 1 | set_auth_challenge | u64 challenge at 16 |
| 2 | get_enrol_challenge | out u64 challenge at 16 |
| 3 | authorize_enrol | length 69 at 12, HAT at 16 |
| 4 | get_auth_result | length 69 at 12, out HAT at 16 |
| 5 | import_wrapped_key | length at 12, opaque blob at 16 |
| 6 | enrol_timeout | seconds at 12, start flag at 16, **result at 20** |

## 5. Enrollment authorization chain

Enrollment (target 11 cmd 2) is refused unless the TA holds an imported
HAT-signing key, a fresh nonzero challenge, and a HAT bound to that challenge
with a valid HMAC-SHA256 (`fpc_check_enrollment_allowance` `0x58b4` →
validation `0x5924`). An all-zero or challenge-only token does not pass, and
enrolling into a temporary RAM database still runs this check `[S]` `[M]`.

| Step | Contract | Evidence |
| --- | --- | --- |
| HAT format | 69 bytes: version (u8, must be 0), challenge (u64), secure user id (u64), authenticator id (u64), authenticator type (u32, **network order**), timestamp (u64, **network order**), HMAC-SHA256 (32 bytes) over the first 37 bytes | `[S]` TA + Android HAT definition |
| Challenge lifetime | ~10 minutes | `[S]` |
| Wrapped key source | HAL opens `keymaster64` with a 1024-byte shared buffer, sends a 64-byte request starting `{0x205, 2}`, receives ≤ 960 bytes: `{status, blob offset, blob length, blob…}`. Observed blob: 152 bytes. FPC unwraps it in secure world and checks the source app name is `keymaster64` (`fpc_ta_hw_auth_unwrap_key` `0x60fc`) | `[S]`, `[M]` |
| Keymaster version handshake | `GET_VERSION 0x200` (4-byte request) → status + `[4, 0, 4, 165]` (TA API major/minor, TA major/minor). `SET_VERSION 0x207` = six words `[0x207, 4, 5, 4, 5, 0]`. SET takes effect **once per loaded TA instance**; later SETs are silently ignored and GET does not read back client settings | `[S]` `libkeymasterdeviceutils.so` constructor `0x22d8`; `[M]` |
| Per-boot HMAC agreement | Until done, `0x205` returns status `-24` (`km_get_auth_token_key` `0xb548` → uninitialized shared-HMAC flag at `0x2a18`). Sequence: `0x20e GET_HMAC_PARAMETERS` → 64-byte seed/nonce, then `0x20f COMPUTE_SHARED_HMAC` (76-byte request, single participant) → 32-byte sharing check. Android does this through the Keymaster HAL at boot | `[S]`, `[M]` |
| **Ordering rule A** | `cmnlib64` must be resident before `fpctzappfingerprint` loads (`DT_NEEDED libcmnlib.so`; ELF64 class selects the 64-bit library) | `[S]`, `[M]` load fails otherwise |
| **Ordering rule B** | `fpctzappfingerprint` must be resident before Keymaster is asked for the wrapped key. Keymaster resolves the recipient by name (`get_fpta_name`, default `fingerprint`) and encapsulates the key for that app (`qsee_encapsulate_inter_app_message`, `0xb77c`). With FPC absent the request failed with `0xff000fff`; with FPC loaded first the identical request returned a valid key | `[S]`, `[M]` lab unit A/B runs, 2026-09-11 |
| Gatekeeper protocol | Inside `keymaster64`, security level 1 (TEE). Older fixed-field format, **not** the CBOR format of newer Qualcomm firmware. `0x1001` enroll, `0x1002` verify. 32-byte header: cmd u32 @0, Gatekeeper uid u32 @4; enroll: old-handle (off,len) @8, old-password (off,len) @16, new-password (off,len) @24; verify: challenge u64 @8, handle (off,len) @16, password (off,len) @24. Payloads appended unpadded. Reply: status i32 @0, blob offset @4, blob length @8, blob @12. Enroll returns a 58-byte handle (secure user id at byte 1); verify returns a 69-byte HAT. Negative status = failure, positive = throttle seconds, never success. Shared buffer `0xa000` bytes, response capacity = `0xa000` − request length | `[S]` `keymaster_b` image; `[M]` enrollment and verification completed on the lab unit |
| Gatekeeper `-30` | Record acquisition failure: the TA could not read its credential table from RPMB. Not a bad-password result | `[S]` verify handler `0x9c00` → `0x9ee0` → storage init `0xf998`; `[M]` reproduced with a synthetic invalid handle |
| Gatekeeper uid space | One numeric table shared with Android. Android 12 user ids stay below 21474 and synthetic-password credentials use `userId` or `100000 + userId`, so ids ≥ `0x70000000` cannot collide with Android's | `[G]` [UserManagerService](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-12.1.0_r1/services/core/java/com/android/server/pm/UserManagerService.java), [SyntheticPasswordManager](https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-12.1.0_r1/services/core/java/com/android/server/locksettings/SyntheticPasswordManager.java) |

Stock flow, in order: Keymaster HAL at boot does the HMAC agreement → FPC HAL
loads `cmnlib64`, then the TA, then imports the wrapped key (target 3 cmd 5) →
on enroll, target 3 cmd 2 yields a challenge → Gatekeeper verifies the user's
credential against that challenge and returns a HAT → target 3 cmd 3 → target
11 cmds 0/1…/2.

## 6. Secure storage (RPMB listener)

Gatekeeper's table lives in the eMMC RPMB partition and is reached through
listener `0x2000`. The wire format is Qualcomm's RPMB listener protocol as
implemented in LK (`platform/msm_shared/rpmb/rpmb_listener.c`) `[T]` and in
stock `librpmb.so` (version-2 layout) `[S]`. What the sargo firmware actually
sends `[M]`, lab unit, 2026-09-11:

| Fact | Value |
| --- | --- |
| Commands | `0x101` init, `0x102` read, `0x103` write, `0x104` partition configuration (stock consults `/system/etc/rpmb_sec_parti.cfg`); listener shared memory 25 KiB |
| Read request | one 512-byte RPMB frame at offset 24; the declared length is **payload bytes**, `count × 256` (observed count 34 → 8704), not frame bytes |
| RW version field | 0 on reads, `0x100` on the observed write. Stock and LK preserve it without interpreting it; it is not the init negotiation version |
| Gatekeeper table init | reads of 34 and 14 frames (24 logical 512-byte sectors), then a 2-frame **authenticated reliable write** (length 1024, offset 24, group 2) |
| RPMB device | 16 MiB, enhanced RPMB supported, `rel_sectors = 1`; stock advertises 32 reliable frames when enhanced RPMB is present |
| MMC shape | CMD25 (reliable-write bit) carrying the request frames, then CMD18 for one result frame; counter read = request type 2 |
| Key programming | never issued by the TA in any observed sequence; a receiver may refuse it outright |

## 7. Interrupt behaviour

| Observation | Evidence |
| --- | --- |
| The line idles low (pull-down) and rises on sensor events; the kernel counts edges | `[G]` driver |
| Target 10 `init` then `deep_sleep` complete with all statuses 0 and no spurious activity | `[M]` daily unit, 2026-09-11 |
| One arm → touch → `qualify_capture` cycle advanced the edge counter from 120 to 144 | `[M]` daily unit, 2026-09-11 |
| On Pixel 3 (blueline, same TA name and command set) `init` produces about 68 edges, `wakeup_setup` and `deep_sleep` one each; a loop that re-arms on every edge feeds itself (1444-event storm) | `[T]` [SouveraineOS task 44](https://forge.caseytunturi.com/Fimeg/SouveraineOS/src/branch/public/docs/tasks/44-fingerprint-fpc1020.md) ([archived 2026-09-14](https://web.archive.org/web/20260914045432/https://forge.caseytunturi.com/Fimeg/SouveraineOS/raw/branch/public/docs/tasks/44-fingerprint-fpc1020.md)); not re-measured on sargo |

## 8. Proof: an independent implementation

The contract above is exercised by a native Linux stack with no Android
userspace: a mainline-based kernel carrying the legacy QSEECOM transport as a
TEE driver plus a reset/IRQ companion, a listener daemon serving FS, GPFS and
RPMB, a Keymaster/Gatekeeper broker, and a libfprint driver. On 2026-09-13
it enrolled several fingers through GNOME Settings and unlocked the Phosh
lockscreen with them on a Pixel 3a, rejecting non-enrolled fingers, with
enrollments surviving reboot. Earlier lab runs on a second sargo unit
established each link of §5 and §6 in isolation. `[I]`

- Kernel: [samcday/linux](https://github.com/samcday/linux) (QSEECOM transport, ELF64 app loading, `fpc1020` companion; e.g. [PR #3](https://github.com/samcday/linux/pull/3) for the invoke-buffer fix).
- Userspace and device integration: [samcday/pocketfed](https://github.com/samcday/pocketfed), device `google-sargo`.

Why the in-tree drivers were not enough: mainline `qcom_qseecom` is a client
for the firmware-preloaded UEFI secure app with a machine allowlist (sargo:
"untested machine, skipping"), and mainline `qcomtee` speaks the object-based
smcinvoke ABI ([kernel docs](https://docs.kernel.org/tee/qtee.html)), a
different generation from the legacy QSEOS app protocol this firmware uses.

## 9. Prior art

| Work | Contribution | Archive |
| --- | --- | --- |
| [wrobelda/goodix-fp-spi-linux](https://github.com/wrobelda/goodix-fp-spi-linux), [`qcom-qseecom-tee` kernel branch](https://github.com/wrobelda/linux/tree/qcom-qseecom-tee), [qsee-supplicant](https://github.com/wrobelda/qsee-supplicant) | Legacy QSEECOM through the Linux TEE subsystem; listeners; Gatekeeper notes for a newer (CBOR) Qualcomm firmware | [archived 2026-09-14](https://web.archive.org/web/20260914045413/https://github.com/wrobelda/goodix-fp-spi-linux) · [supplicant](https://web.archive.org/web/20260914050014/https://github.com/wrobelda/qsee-supplicant) |
| [SouveraineOS task 44 (Pixel 3 / blueline)](https://forge.caseytunturi.com/Fimeg/SouveraineOS/src/branch/public/docs/tasks/44-fingerprint-fpc1020.md) | FPC TA command numbering and IRQ measurements on blueline; its raw-IRQ PAM bridge is not authentication | [archived 2026-09-14](https://web.archive.org/web/20260914045432/https://forge.caseytunturi.com/Fimeg/SouveraineOS/raw/branch/public/docs/tasks/44-fingerprint-fpc1020.md) |
| [Catcrafts fingerprintd (Fairphone 6)](https://forgejo.catcrafts.net/Catcrafts/fingerprintd) | Native daemon lifecycle reference; Focaltech sensor on newer QTEE, different path | [archived 2026-09-14](https://web.archive.org/web/20260914050108/https://forgejo.catcrafts.net/Catcrafts/fingerprintd) |
| [Pixel 3a stock boot trace](https://gist.github.com/tanyeun/64a7a54410b14195aac60c8bca8285ab) | Shows `qseecomd` and the TA loading during an Android 9 boot | [archived 2026-09-14](https://web.archive.org/web/20260914045252/https://gist.github.com/tanyeun/64a7a54410b14195aac60c8bca8285ab) |
| [lk2nd](https://github.com/msm8916-mainline/lk2nd) `platform/msm_shared/rpmb/` (commit `4a88d4cc9d6da226a90e55f2a0e66f7179a0b79b`) | Open implementation of the RPMB listener protocol (0x101–0x103) | — |

## 10. Open questions

- Sensor die revision and secure SPI controller routing are not measured.
- Target 10 cmd 1's boolean semantics and cmd 7's payload are not decoded.
- Names of the six identify diagnostics words (aux 16–39) beyond `decision` are unconfirmed.
- Whether the TA ever issues RPMB `0x104` (partition configuration) on a fresh table.
- The precise meaning of Keymaster status `0xff000fff` beyond "recipient not resident".
- Blueline's IRQ edge counts have not been re-measured on sargo.
