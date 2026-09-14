# Fingerprint — Google Pixel 3a (`google/sargo`)

> **Status: working end-to-end.** Native enrollment via GNOME Settings and
> fingerprint unlock of the Phosh lockscreen **passed acceptance on
> `sam-sargo` on 2026-09-13**, with SELinux enforcing and PIN fallback intact.
> Public acceptance record: [samcday/sam-sargo#11](https://github.com/samcday/sam-sargo/issues/11).
>
> Accepted stack: kernel `7.1.2-0.pocketfed.sdm670.12.fc46` · libfprint
> `1.94.100-1.6.pocketfed.fc46` · gnome-control-center `51~rc.1-1.2.fingerprint.fc46`
> · phosh `0.57.0-1.5.fingerprint.fc46` · stock fprintd (no fork needed for
> D-Bus/PAM integration).

Everything in this page is either (a) verifiable in Google's published kernel
sources, (b) measured from a retained stock vendor partition pinned to an exact
Android build, or (c) implemented and acceptance-tested in
[samcday/pocketfed](https://github.com/samcday/pocketfed) and
[samcday/linux](https://github.com/samcday/linux). Volatile third-party pages
are deep-linked to permanent archive.org snapshots captured 2026-09-14.

---

## 1. Hardware

| Fact | Value | Evidence |
| --- | --- | --- |
| Sensor | Rear-mounted FPC1020-family touch sensor | stock DT compatible `fpc,fpc1020` — [Google kernel source](https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-bonito-4.9-android12L/arch/arm64/boot/dts/google/sdm670-b4s4-fingerprint.dtsi) ([archived](https://web.archive.org/web/20260914050018/https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-bonito-4.9-android12L/arch/arm64/boot/dts/google/sdm670-b4s4-fingerprint.dtsi)) |
| IRQ | **TLMM GPIO 121**, `bias-pull-down`, drive-strength 2 | same DT: `interrupts = <121 0x0>`, `fpc,gpio_irq = <&tlmm 121 0x0>` |
| Reset | **TLMM GPIO 134**, pinctrl states `fpc_reset_low` / `fpc_reset_high` | same DT: `fpc,gpio_rst = <&tlmm 134 0x0>` |
| Bus | Not a Linux-visible SPI device; sensor commands go through TrustZone | live sargo: only `spi0.0` (`rt5514` audio) — [feasibility inventory](https://github.com/samcday/sam-sargo/issues/11) |
| SoC | Qualcomm SDM670; QSEE reserved region `qseecom@9e400000`, 20 MiB | live device tree, 2026-09-10 inventory (`devices/google-sargo/diagnostics/2026-09-10-fingerprint/` in pocketfed) |

The compatible string establishes the **driver family, not a measured part
revision** — treat "FPC1020" as the interface contract, not a die-step claim.

## 2. Stock (Android) software architecture

### 2.1 Firmware provenance — the last build Google ever shipped

The retained stock vendor on `sam-sargo` identifies as:

```
google/sargo/sargo:12/SP2A.220505.008/8782922:user/release-keys
security patch 2022-05-05
```

**SP2A.220505.008 is the final sargo OTA**: guaranteed updates ended May 2022
([Google's Pixel update schedule](https://support.google.com/pixelphone/answer/4457705?hl=en),
[archived 2026-09-14](https://web.archive.org/web/20260914050228/https://support.google.com/pixelphone/answer/4457705?hl=en));
Google shipped one farewell build replacing SP2A.220505.006
([XDA](https://www.xda-developers.com/google-pixel-3a-and-pixel-3a-xl-september-security-update/),
[9to5Google](https://9to5google.com/2022/06/07/pixel-3a-last-update/)).
So every stock fingerprint binary described below is from the **terminal
firmware release** for this device — there is no newer vendor side to chase.

A second handset (`test-sargo`, vendor `SP2A.220505.002`) carries
**byte-identical** fingerprint/common-library firmware — all 16 files hash-equal
across both builds (measured 2026-09-13, `fingerprint-trial/lab/` records).

### 2.2 The binary set (16 files)

Extracted read-only from `/dev/mapper/vendor_b` via `debugfs` (no mount, no
write), pinned in `devices/google-sargo/fingerprint-trial/firmware-manifest.json`:

- **`fpctzappfingerprint`** (QSEE trusted application): `.mbn` = **691,540
  bytes, ELF64 / AArch64** (machine 183, **8 program headers**),
  SHA-256 `e947fd8b081b47be9bd75c87cbd95a79fd8955b9d3310631680ca47fd76997e8`.
  Shipped as `.mdt` + `.b00`–`.b07`; raw `.mdt` = `.b00`+`.b01`. **Zero ELF
  section headers** — but dynamic symbols are retained, which is how the
  command interface was recovered.
- **`cmnlib64`** (QSEE common library): ELF64, 6 program headers, `.mdt` +
  `.b00`–`.b05`.
- Android-side userspace in the same vendor image: `/bin/hw/android.hardware.biometrics.fingerprint@2.1-service.fpc`,
  `/lib64/libQSEEComAPI.so`, `com.fingerprints.extension@1.0.so`, `/bin/qseecomd`.
  The HAL's ELF dependency table names `libQSEEComAPI.so` directly.

An Android-9-era Pixel 3a boot trace shows the same TA loading in stock use:
[tanyeun's gist](https://gist.github.com/tanyeun/64a7a54410b14195aac60c8bca8285ab)
([archived](https://web.archive.org/web/20260914045252/https://gist.github.com/tanyeun/64a7a54410b14195aac60c8bca8285ab)).

### 2.3 Who does what

- **Stock kernel driver** `drivers/input/misc/fpc_fingerprint/fpc1020_platform_tee.c`
  (`CONFIG_FPC_FINGERPRINT`) —
  [source](https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-bonito-4.9-android12L/drivers/input/misc/fpc_fingerprint/fpc1020_platform_tee.c)
  ([archived](https://web.archive.org/web/20260914050043/https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-bonito-4.9-android12L/drivers/input/misc/fpc_fingerprint/fpc1020_platform_tee.c)) —
  supplies GPIO/reset electrical control and a polled sysfs IRQ **only**. It
  sends no sensor commands and does no matching. All biometrics live in the TA.
- **QSEE secure world** executes `fpctzappfingerprint`; userspace reaches it
  through the legacy QSEECOM `ioctl` API via `libQSEEComAPI.so`/`qseecomd`.
- **Enrollment is authorization-gated**: the TA demands a **signed hardware
  authentication token**, minted by Gatekeeper/Keymaster against an FPC-provided
  challenge (measured on-device; see §4.3).

## 3. Secure-world contract (measured on sargo)

> Sources: dynamic-symbol recovery of the sargo TA + HAL, on-device probing
> during the Sep 2026 trial (thread + `fingerprint-trial/` records), cross-checked
> against the Pixel 3 / blueline protocol reconstruction in
> [SouveraineOS task 44](https://forge.caseytunturi.com/Fimeg/SouveraineOS/src/branch/public/docs/tasks/44-fingerprint-fpc1020.md)
> ([archived](https://web.archive.org/web/20260914045432/https://forge.caseytunturi.com/Fimeg/SouveraineOS/raw/branch/public/docs/tasks/44-fingerprint-fpc1020.md)).

### 3.1 App loading (legacy QSEECOM)

- Boot log reports QSEECOM version `0x1400000`; a `GET_QSEECOM_INFO`-style
  version query reaches secure firmware out of the box.
- `LOAD_APP` = app-manager command 1 (`TZ_OS_APP_START_ID`), three value
  params `(mdt_len, img_len, phys)`. The image is the `.mdt` ELF header blob
  plus one `.bNN` per program header, reassembled **contiguously at
  `p_paddr`-relative offsets** in `dma_alloc_coherent` memory under a 32-bit
  DMA mask.
- Sargo's TA is **ELF64** — downstream QSEECOM images of this generation are
  64-bit, which the stock transport on mainline did not support (§5.1).
- A machine-wide QSEE **storage listener** (one receiver per device, not per
  app) must exist for TA filesystem access; listener id `0x5000` (ssd) is
  registrable against the signed TZ image (blueline doc).

### 3.2 FPC TA command interface

Commands travel in a shared **0x58-byte aux buffer** whose first two words are
`0x0A` (target 10 base marker) and the command id; larger payloads go in a
second buffer.

| Target | Cmd | Meaning |
| --- | --- | --- |
| 10 (sensor) | 0 | `init` |
| 10 | 3 | `wakeup_setup` (arm) |
| 10 | 5 | `deep_sleep` |
| 10 | 1 | `check_finger_lost` |
| 10 | 4 | `qualify_capture` |
| 11 (bio) | 0 / 1 / 2 | `begin_enrol` / `enrol` / `end_enrol` |
| 11 | 3 | `identify` |
| 11 | 6 / 9 | `load_empty_db` / `set_active_fingerprint_set` |
| 11 | 7 / 8 | `get_template_ids` / `delete_template` |
| 2 | — | template persistence (machine-wide QSEE storage listener) |

Flow mapping: `EnrollStart` = `11/6 → 11/9 → 11/0`, each capture `10/4 → 11/1`,
`EnrollStop` = `11/2`. `VerifyStart` = `10/3`, then on IRQ `10/1 → 10/4 → 11/3`.

**Measured IRQ behavior**: the sensor asserts its interrupt at power-up and
latches it high until TA traffic rearms the line. `init` produces ~68 IRQ
edges; `wakeup_setup` and `deep_sleep` produce one each — so naive re-arm
loops self-feed (blueline doc measured a 1444-event storm this way). A touch
interrupt must never count as authentication.

### 3.3 Enrollment authorization chain (the hard part)

Measured on sargo, in order:

1. **FPC** issues a challenge that enrollment tokens must sign.
2. **Keymaster** (`keymaster64` TA) must be initialized first: it requires a
   **per-boot HMAC key-sharing setup** before it will serve wrapped
   authentication keys (exact request/reply layout recovered from stock
   `libkeymasterdeviceutils.so` and friends; see `keymaster-negotiate.c`,
   `keymaster-sharing.c` in pocketfed `fingerprint-trial/`).
3. **Ordering invariant: the FPC TA must be loaded *before* Keymaster wraps its
   authentication key.** Discovered on `test-sargo` — with FPC loaded first,
   the wrapped-key request succeeds (`-30` otherwise).
4. **Gatekeeper** (older, fixed-field protocol on this generation) verifies a
   credential and returns the signed token bound to the FPC challenge; the TA
   validates it. Gatekeeper status `-30` = secure-storage record failure.
5. Gatekeeper's records live in **RPMB** (16 MiB region) behind QSEE storage
   listeners **FS / GPFS / RPMB** (one receiver). Protocol details that bit us:
   - read-request version field is **0**, not 2 (stock listener never checks it);
   - the length field counts **256-byte payload blocks** (e.g. 34 blocks =
     8,704 bytes), *not* 512-byte transport frames;
   - table initialization uses **authenticated writes**; the RW metadata field
     must be preserved as received;
   - a safe receiver refuses RPMB key programming and stops writing after any
     transport/device error.

## 4. The Linux implementation (PocketFed)

### 4.1 Kernel layer — [samcday/linux](https://github.com/samcday/linux)

Fedora kernel 7.1.2 base + the [sdm670-mainline](https://gitlab.com/sdm670-mainline/linux-patches)
patch stack. Production release `.12` = commit `3ad4e5eac8aa16c1e6dcf291fdec4fb906f803d0`
(ARM64 [COPR build 10980882](https://copr.fedorainfracloud.org/coprs/build/10980882));
preserved `.11` trial source = `132283913205a1db1d57fc3e563eea8224f5b79a`.

| Commit | What it provides |
| --- | --- |
| `c57a78c151020` | `tee: import legacy Qualcomm QSEECOM transport` — the downstream app-loading/ioctl protocol as a TEE client |
| `789eb5b22a489` | `tee: qseecom: support Sargo ELF64 images and harden session lifetimes` |
| `2e950df3ef4b5` | `tee: qseecom: wipe application invoke staging before release` |
| `cad152be638f4` | `tee: qseecom: reuse the device pool for invoke staging` — the CPU-stall fix; see [samcday/linux PR #3](https://github.com/samcday/linux/pull/3) |
| `5efc7e2b2ca9f` | `misc: add Sargo fingerprint reset and IRQ companion` — `drivers/misc/fpc1020.c`, DT binding `google,sargo-fingerprint`, `CONFIG_FPC1020`, UAPI `linux/fpc1020.h`: exclusive misc device with IRQ counter, level snapshot, reset, opt-in wakeup. Deliberately **no sensor commands, no matching** (same split as stock) |

Why not what's already upstream:

- mainline `qcom_qseecom` (UEFI secapp client) uses a machine allowlist — sargo
  hits *"untested machine, skipping"*, and it assumes apps are pre-loaded by
  firmware anyway;
- mainline `qcomtee` implements the object-based **smcinvoke** protocol, a
  different generation of TEE ABI — not a drop-in for the legacy app protocol
  ([kernel docs](https://docs.kernel.org/tee/qtee.html)).

The invoke-pool bug is worth knowing about: per-invoke TZ staging allocation
survived initialization but left firmware-loader shutdown stalled → watchdog
reset. The fix reuses the device-owned TZ pool (keeping coherent backing
mappings alive across commands) while clearing/freeing each staging buffer.
Evidence: disposable A/B comparison (only the allocator parameter changed — old
allocator stalls, pool reuse completes), then 50 native cycles / 10 firmware
lifetimes / 50,000 allocations / 30 clean service stops, plus a synthetic
24-case fixture at 4 KiB and 64 KiB pages
([pocketfed PR #62](https://github.com/samcday/pocketfed/pull/62)).

### 4.2 Userspace layer

- **Native FPC libfprint driver** (libfprint `1.94.100.x`): enrollment,
  gallery-bound matching, deletion, cancellation; talks QSEECOM through the TEE
  device and the `fpc1020` companion for reset/IRQ. Knows the empty-gallery
  rule: never ask `identify` with an empty template DB (`load_empty_db` first).
  Driver sources (latest preserved snapshot):
  `~/src/pocketfed/out/fingerprint-kernel-pool-20260913/native-source*/`
  (`protocol.c`, `qsee-transport.c`, `sensor.c`, `initialize.c`).
- **QSEE loaders + storage listener daemon**: loads `cmnlib64` then
  `fpctzappfingerprint` (in that order — §3.3), registers **FS + GPFS + RPMB**
  listeners in one receiver. Units: `qsee-shared-loader@cmnlib64.service`,
  `qsee-app-loader@fpctzappfingerprint.service`,
  `pocketfed-fingerprint-firmware.service`. RPMB probe: `rpmb-counter-check.c`.
- **Enrollment-token broker**: privileged daemon between fprintd and
  Keymaster/Gatekeeper. Attaches only to `keymaster64`, runs the version
  handshake and per-boot HMAC setup (idempotent), reserves Gatekeeper UIDs
  **outside Android's user ranges** (lab credential `0x700004d2`) so enrollment
  never clobbers Android secure state, enforces challenge-bound tokens,
  throttling, and refusal to retry ambiguous enrollments.
- **Firmware provisioning**: `extract-firmware.py` reads the 16 stock files
  read-only from `vendor_b`, hash-checks against the pinned manifest, and
  stages them device-locally (`/var/lib/firmware-updates`) so boot doesn't
  depend on a transient vendor mapping (`--ensure` reuse path).
- **SELinux**: a small policy module lets fprintd reach the sensor/TEE nodes
  and the broker socket, and *not* read broker credentials. The image's
  compiled policy was reconstructed byte-for-byte as a baseline before adding
  the module, preserving all existing rules/contexts. Enforcing throughout.
- **Desktop integration** (two real GNOME Settings bugs): enrollment UI hides
  when the optional GDM settings schema is absent — patched to still show; and
  a second-enrollment `VerifyStop`/`EnrollStart` ordering bug — fixed. Phosh
  ships a PAM helper while preserving the distribution PAM policy byte-for-byte
  (homed/PIN fallback intact).

### 4.3 Agreed behavior model

**"PIN once after reboot, then fingerprints."** After boot, the first unlock is
PIN (this releases the homed unlock path); fingerprints work for the rest of
the session and enrollment persists across reboots. Fingerprint-only
decryption of a cold encrypted home and Phrog login were explicitly de-scoped
(`fingerprint-trial/acceptance.md`).

## 5. Acceptance evidence (2026-09-13, `sam-sargo`)

- First trial boot from validated image: 16 firmware files hash-verified, both
  QSEE storage listeners + TA loaded first attempt, sensor `init`/`deep_sleep`
  clean, touch registered, fprintd database created after Keymaster HMAC setup.
- GNOME Settings: additional fingers enrolled, dialog reopen cycles,
  matching/non-matching tester feedback.
- Phosh: multiple enrolled fingers unlock; wrong-finger rejection; PIN fallback
  then fingerprint; ~6 mixed Settings/lockscreen cycles confirmed by user.
- Normal reboot preserved enrollment metadata; fingerprint socket auto-started.
- Stability: 50 fprintd Claim/Release cycles across 10 service lifetimes +
  50 explicit stops in **58.35 s** on the packaged `.12` stack; independent
  UART observation showed no stall signatures.
- Full public record: [sam-sargo#11](https://github.com/samcday/sam-sargo/issues/11);
  engineering ledger: `~/src/pocketfed/devices/google-sargo/fingerprint-trial/`
  (`acceptance.md`, `live-trial-20260911.md`, `image/README.md`, `lab/README.md`).

## 6. Open gaps (post-acceptance)

- Kernel series integration: PR #3 sits on the preserved `.11` trial branch,
  not the maintained release branch; the whole prerequisite series needs a
  landing review.
- Userspace sources/tests/packaging still live as local trial snapshots —
  need extraction into reviewable, signed-pipeline builds.
- PocketFed `main` images do not yet contain any of this.
- UX: Phosh's wrong-fingerprint message is too brief.
- Reliability beyond the finite test series, and the underlying platform fault
  behind the invoke-pool stall, are not formally established.
- Fingerprint-only cold-home (homed) unlock remains future work by design.

## 7. Prior art this built on

| Work | Contribution | Archive |
| --- | --- | --- |
| [wrobelda/goodix-fp-spi-linux](https://github.com/wrobelda/goodix-fp-spi-linux) (+ [`qcom-qseecom-tee` kernel branch](https://github.com/wrobelda/linux/tree/qcom-qseecom-tee), [qsee-supplicant](https://github.com/wrobelda/qsee-supplicant)) | legacy QSEECOM transport through the TEE subsystem; app loading, shared buffers, listeners; Goodix `gfenu` on SM8250 | [repo](https://web.archive.org/web/20260914045413/https://github.com/wrobelda/goodix-fp-spi-linux) · [supplicant](https://web.archive.org/web/20260914050014/https://github.com/wrobelda/qsee-supplicant) |
| [SouveraineOS task 44 (Pixel 3 / blueline FPC1020)](https://forge.caseytunturi.com/Fimeg/SouveraineOS/src/branch/public/docs/tasks/44-fingerprint-fpc1020.md) | the FPC TA protocol reconstruction used to seed §3.2 | [archived](https://web.archive.org/web/20260914045432/https://forge.caseytunturi.com/Fimeg/SouveraineOS/raw/branch/public/docs/tasks/44-fingerprint-fpc1020.md) |
| [Catcrafts fingerprintd (Fairphone 6)](https://forgejo.catcrafts.net/Catcrafts/fingerprintd) | native daemon lifecycle reference (Focaltech `focal64`, newer QTEE — different path) | [archived](https://web.archive.org/web/20260914050108/https://forgejo.catcrafts.net/Catcrafts/fingerprintd) |
| Stock GPLv2 FPC driver + board DT | exact sargo reset/IRQ electricals | §1/§2.3 links |
| [Pixel 3a stock boot trace](https://gist.github.com/tanyeun/64a7a54410b14195aac60c8bca8285ab) | confirms TA/`qseecomd` flow on device | [archived](https://web.archive.org/web/20260914045252/https://gist.github.com/tanyeun/64a7a54410b14195aac60c8bca8285ab) |

## 8. Verify it yourself

```sh
# Stock DT contract (live + archived above)
curl -s 'https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-bonito-4.9-android12L/arch/arm64/boot/dts/google/sdm670-b4s4-fingerprint.dtsi?format=TEXT' | base64 -d

# Firmware manifest pinned to the final OTA build
jq . ~/src/pocketfed/devices/google-sargo/fingerprint-trial/firmware-manifest.json

# Kernel series, from the .12 production tree
git -C ~/src/pocketfed-kernel-fpc-pool show --stat \
  5efc7e2b2ca9f cad152be638f4 c57a78c151020 789eb5b22a489

# Public acceptance record
gh issue view 11 -R samcday/sam-sargo
```
