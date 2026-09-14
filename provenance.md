# Provenance — the immutable base

Everything in this book is anchored to the last software Google shipped for
the Pixel 3a and to the kernel source Google published for it. This chapter
establishes that base, records how each piece of evidence was obtained, and
lists what is still not pinned. Chapters cite this page instead of restating
it. Evidence classes: see [CLANKER-README.md](CLANKER-README.md).

## 1. The device

| Fact | Value | Evidence |
| --- | --- | --- |
| Product | Google Pixel 3a, codename `sargo`; sibling Pixel 3a XL is `bonito`. Board family `b4s4` (`B4` = bonito, `S4` = sargo) | `[G]` factory image `android-info.txt`: `require board=bonito\|sargo`; DT overlays named `… sdm670 S4 …` |
| SoC | Qualcomm SDM670 | `[G]` base DTB `model = "Qualcomm Technologies, Inc. SDM670 SoC"`, `compatible = "qcom,sdm670"` |
| Board DT identity | `compatible = "google,b4s4-sdm670", "qcom,sdm670"`; `qcom,msm-id = <0x150 0>`; sargo board ids `0x40205` (Dev), `0x40305` (Proto), `0x40a05` (EVT), `0x41405` (DVT), `0x41e05` (PVT) | `[G]` `dtbo.img` overlays 1/3/5/7/9 |
| Running identity | `/proc/device-tree/model` = `Google Pixel 3a`, compatible `google,sargo qcom,sdm670` (mainline DT naming) | `[M]` daily unit, 2026-09-14 |
| Storage | eMMC, 62,537,072,640 bytes, manufacturer id `0x90`; RPMB 16 MiB with enhanced RPMB | `[M]` daily unit |

## 2. The final build

| Fact | Value | Evidence |
| --- | --- | --- |
| Build | `SP2A.220505.008`, incremental `8782922`, fingerprint `google/sargo/sargo:12/SP2A.220505.008/8782922:user/release-keys`, security patch `2022-05-05` | `[G]` `vendor.img` `build.prop`; `[M]` retained vendor partition on both units |
| AOSP tag | `android-12.1.0_r27` (Android 12L), devices "Pixel 3a, Pixel 3a XL" | `[G]` [AOSP build numbers](https://source.android.com/docs/setup/reference/build-numbers) |
| Predecessors | `SP2A.220505.006` = `android-12.1.0_r6`; `SP2A.220505.002` = `android-12.1.0_r5` (the last build shared with other Pixels) | `[G]` same table |
| It is the last one | Google's update guarantee for the 3a ended May 2022; the `.008` build was pushed in September 2022 as a final update without a new patch level. No later build exists in Google's tables | `[G]` build-numbers table has no later sargo entry; `[T]` [XDA, 2022-09-07](https://www.xda-developers.com/google-pixel-3a-and-pixel-3a-xl-september-security-update/), [9to5Google, 2022-06-07](https://9to5google.com/2022/06/07/pixel-3a-last-update/), [Google support](https://support.google.com/pixelphone/answer/4457705?hl=en) ([archived 2026-09-14](https://web.archive.org/web/20260914050228/https://support.google.com/pixelphone/answer/4457705?hl=en)) |
| Factory image | `sargo-sp2a.220505.008-factory-071e368a.zip`, 1,906,636,795 bytes, SHA-256 `071e368a127ce5a3c553f8b717895eaf1e44dec78971dc4c80baa7237d2d37f1` | `[G]` [download](https://dl.google.com/dl/android/aosp/sargo-sp2a.220505.008-factory-071e368a.zip), hash verified 2026-09-14; listed on [developers.google.com/android/images](https://developers.google.com/android/images#sargo) |
| Bootloader | `bootloader-sargo-b4s4-0.4-8048689.img`, SHA-256 `3db0d003dd65ecf30caf515bfe3563ee760ae7004577483c67915b9b6870ab67`; required `version-bootloader=b4s4-0.4-8048689` | `[G]` factory image |
| Radio | `radio-sargo-g670-00145-220106-b-8048689.img`, SHA-256 `74f7eb3c384cf76e93b487d081650665c4d066ec305ab82972aef795ef729836`; required `version-baseband=g670-00145-220106-B-8048689` | `[G]` factory image |
| boot.img | 67,108,864 bytes, SHA-256 `4fff7d43dbf56e213a420e20acddfab42596a39c3b0f6dcd0d04c0e37b86f5ed`; header v2, page 4096, kernel 20,498,956 bytes (LZ4), ramdisk 14,258,512, DTB 1,240,260 at `0x1f00000`, OS 12.0.0 / 2022-05 | `[G]` factory image, `image-sargo-sp2a.220505.008.zip` |
| Stock kernel cmdline | `console=ttyMSM0,115200n8 androidboot.console=ttyMSM0 printk.devkmsg=on msm_rtb.filter=0x237 ehci-hcd.park=3 service_locator.enable=1 firmware_class.path=/vendor/firmware cgroup.memory=nokmem lpm_levels.sleep_disabled=1 loop.max_part=7 androidboot.boot_devices=soc/7c4000.sdhci androidboot.super_partition=system buildvariant=user` | `[G]` boot.img header |
| Vendor blobs | `google_devices-sargo-sp2a.220505.008-772e1993.tgz`, `qcom-sargo-sp2a.220505.008-8c718226.tgz` | `[G]` [driver binaries page](https://developers.google.com/android/drivers#sargosp2a.220505.008) |

## 3. The kernel source

| Fact | Value | Evidence |
| --- | --- | --- |
| Shipped kernel | `Linux version 4.9.292-gab4493f31457-ab8272301 (android-build@abfarm592) (Android (7284624, based on r416183b) clang version 12.0.5 …)` | `[G]` string inside the decompressed kernel from `boot.img` |
| Source commit | `kernel/msm` **`ab4493f31457eea175568b18b8300d4d12aaeea8`**, committed 2022-03-08 (`Merge branch 'android-msm-pixel-4.9-sc-security' into android-msm-pixel-4.9-sc-v2`); `Makefile` says 4.9.292 | `[G]` [commit](https://android.googlesource.com/kernel/msm/+/ab4493f31457eea175568b18b8300d4d12aaeea8). The `-g` suffix of the shipped version string is this hash |
| Branch and tags | head of `android-msm-bonito-4.9-android12L`; tags `android-12.1.0_r0.17` and `android-12.1.0_r0.23` | `[G]` googlesource refs, 2026-09-14 |
| Build recipe | [`kernel/manifest`](https://android.googlesource.com/kernel/manifest/+/refs/heads/android-msm-bonito-4.9-android12L/default.xml) branch `android-msm-bonito-4.9-android12L`: `kernel/msm` at `private/msm-google`, `kernel/msm-extra` (audio techpack), three `qcacld-3.0` WLAN projects, clang from `platform/prebuilts/clang/host/linux-x86`. `build.config.bonito` selects `bonito_defconfig` | `[G]` |
| Config facts used by chapters | `CONFIG_QSEECOM=y`, `CONFIG_FPC_FINGERPRINT=y` | `[G]` `bonito_defconfig` at the commit |
| DT layout | `boot.img` carries the SoC base DTB (`sdm670.dtsi` tree); board content, including the fingerprint node, is applied from `dtbo.img` overlays selected by board id | `[G]` decompiled `boot.img` DTB and `dtbo.img` |

Vendored copies of the files chapters quote, with hashes and a re-fetch
script: [`vendor/kernel-msm-ab4493f31457eea175568b18b8300d4d12aaeea8/`](vendor/kernel-msm-ab4493f31457eea175568b18b8300d4d12aaeea8/VENDORED.md).

## 4. Partition map

GPT of a sargo unit, read by partition label `[M]` (daily unit, 2026-09-14).
Sizes in bytes. Slot suffixes `_a`/`_b` omitted where both exist.

| Partition | Size | Notes |
| --- | ---: | --- |
| `cdt` | 134,144 | p1 |
| `xbl`, `xbl_config` | 3,670,016 / 131,072 | primary bootloader (A/B) |
| `tz` | 2,097,152 | QSEE / TrustZone OS (A/B), ELF64, 17 program headers |
| `aop`, `hyp` | 524,288 each | A/B |
| `fsg`, `modemst1`, `modemst2`, `modemcal` | 2,097,152 each | modem NV / calibration |
| `boot` | 67,108,864 | A/B, Android boot image v2 |
| `keymaster` | 524,288 | A/B, ELF64, 8 program headers: the `keymaster64` TA (Keymaster + Gatekeeper) |
| `cmnlib` | 524,288 | A/B, ELF32 (`e_machine` 40): 32-bit QSEE common library |
| `cmnlib64` | 524,288 | A/B, ELF64: 64-bit QSEE common library |
| `modem` | 115,343,360 | A/B |
| `msadp`, `apdp`, `devcfg`, `qupfw`, `storsec` | 262,144 / 262,144 / 131,072 / 65,536 / 131,072 | A/B |
| `reserved` | 64,487,424 | p25 |
| `abl` | 2,097,152 | A/B, Android bootloader (fastboot) |
| `dip`, `devinfo`, `spunvm`, `dpo`, `splash`, `limits`, `toolsfv`, `logfs`, `ddr`, `sec`, `fsc`, `ssd`, `bluetooth` | various | see raw listing below |
| `dtbo` | 8,417,280 | A/B |
| `persist` | 41,943,040 | |
| `misc`, `keystore`, `frp`, `sti`, `uefivar`, `ImageFv` | 1,048,576 / 524,288 / 524,288 / 2,097,152 / 1,048,576 / 2,097,152 | |
| `rawdump` | 134,217,728 | |
| `vbmeta` | 65,536 | A/B |
| `klog` | 4,194,304 | |
| `metadata` | 16,777,216 | |
| `ffufw` | 4,194,304 | |
| `system` | 3,267,362,816 | A/B. **Acts as the dynamic-partition "super"** (`androidboot.super_partition=system`): `vendor`, `product`, `system_ext` are logical partitions inside it |
| `vendor` | 805,306,368 | A/B, physical partition retained from the pre-dynamic layout; not where the live vendor filesystem lives |
| `userdata` | 53,648,801,280 | |

Fixed secure-world images. Google ships them inside the FBPK bootloader
package (`bootloader-sargo-b4s4-0.4-8048689.img`: 13 entries, a partition
table plus `xbl`, `xbl_config`, `tz`, `aop`, `hyp`, `keymaster`, `cmnlib`,
`cmnlib64`, `abl`, `devcfg`, `qupfw`, `storsec`). The daily unit's partitions,
zero-padded to partition size, hash identically in both slots and match these
images exactly `[G]` `[M]`:

| Image | Bytes in package | SHA-256 of the package image | SHA-256 of the padded partition (both slots) |
| --- | ---: | --- | --- |
| `tz` | 2,048,000 | `947289d2af58aa2e86e3b5c995d5faf5f9b30ebfc2d6eebd50fc3e4462f07160` | `1d4509a8419c0be79e57982cce7f86c3f133a8b55418d96bb2b2f71ed9567268` |
| `keymaster` | 221,184 | `27825a0263a894378e9e87e4d5c3ee28dcf9ab657e483383fdf57bc6219aa894` | `8f800f36d6eef63373dc502462c5f52d1d779dd078e0ae429108ea86fcbb261a` |
| `cmnlib` | 376,832 | `906ad4950bab6066b2f8c2dac845341bf1eb96e0d5875b56d4d5aca7672e24e4` | `0f90b1837487ecd34d0594fdbe3a6d9086aadd0f0107c311c096c90315276fa6` |
| `cmnlib64` | 491,520 | `dbc486e60f4eecf802f68a109af77a27b8011c7c93e2c18c7a67c2fea3155553` | `2e3d7ef41414b33065928fc9ac9b9d284daf3437aacfef446f47e2fedb08a316` |

FBPK v1 layout, for anyone re-deriving this: magic `FBPK`, `u32 version = 1`,
`char img_version[68]`, `u32 entries`, `u32 total_size`; then chained entries
of `u32 type` (0 = partition table, 1 = image), `char name[36]`, `u32 size`,
`u32 pad`, `u32 next_entry_offset`, `u32 crc`, followed by the image bytes.

## 5. Stock vendor filesystem and the fingerprint binaries

**Primary source `[G]`:** `vendor.img` from the factory image (Android sparse
image, 507,711,488 bytes raw, ext4). Files were read with `debugfs` without
mounting. **Corroboration `[M]`:** the same files read from the retained
stock vendor filesystem on two sargo units, one on build `.008` (daily unit)
and one on `.002` (lab unit). All 16 firmware files and every library below
are byte-identical across all three sources.

How the on-device copy was reached: on this A/B layout the live vendor
filesystem is a logical partition inside `system_b`; its extent is
`0 991624 linear <system_b> 1759464` (512-byte sectors), which a read-only
device-mapper table reproduces. `debugfs` was used without `-w`; nothing
was mounted or written.

Manifest (vendored, machine-readable):
[`vendor/firmware/SP2A.220505.008/fingerprint-manifest.json`](vendor/firmware/SP2A.220505.008/fingerprint-manifest.json).
It records lengths, SHA-256, ELF class/machine/program-header count and the
per-segment sizes; it contains no firmware bytes.

| Path in `/vendor` | Bytes | SHA-256 |
| --- | ---: | --- |
| `firmware/fpctzappfingerprint.mbn` (assembled TA) | 691,540 | `e947fd8b081b47be9bd75c87cbd95a79fd8955b9d3310631680ca47fd76997e8` |
| `firmware/fpctzappfingerprint.mdt` | 7,208 | `3d23e9a669df46ab3bc50af44215670a5de60be1f623e0e20e69e0bdcce3ab71` |
| `firmware/fpctzappfingerprint.b00` … `.b07` | 512, 6,696, 522,392, 165, 57,576, 720, 304, 85,332 | see manifest |
| `firmware/cmnlib64.mdt` | 7,032 | `06a32dccef0ef00451e1e002e41bf955ea2952a5d94a87749cc9faf11bd7cdb4` |
| `firmware/cmnlib64.b00` … `.b05` | 400, 6,632, 436,992, 4,240, 288, 30,371 | see manifest |
| `bin/hw/android.hardware.biometrics.fingerprint@2.1-service.fpc` | 63,360 | `11b4f4069ef6fd8b06147be8a696944aa50d664c6969a30f40ee224440a6de48` |
| `lib64/libQSEEComAPI.so` | 31,784 | `6ae96f5eda8f4411c42f9323cabe82f4ecea58a1692d409df21892aa1ba71859` |
| `lib64/libkeymasterdeviceutils.so` | | `39a8184c331d5c7f0fa5c0e02d50499edfa2b905f8ce097732f23a7b774a5bc2` |
| `lib64/librpmb.so` | 29,488 | `63471d0417b101723e6d99ac58de71f0ef57281f4f705a2c8880d18a64bc0bf2` |
| `lib64/com.fingerprints.extension@1.0.so` | | `67ca56bdc1de71a38acf714fdee45968adef55b5653cf2a2853dbd29b33da8af` |
| `bin/qseecomd` | 15,744 | `950008ef38194d6aee2c71a8df926f817812e7b3816075ab6722821cdafb6e6d` |

Structural facts `[S]`:

- Both `.mdt` files are little-endian ELF64 AArch64 and equal `b00 + b01`
  byte for byte. Every `.bNN` length equals its program header's file size.
- `fpctzappfingerprint` has **no section headers**, yet `PT_DYNAMIC` yields
  1101 dynamic symbols and relocation records. This is what made the command
  interface recoverable (fingerprint.md §4). `DT_NEEDED` = `libcmnlib.so`.
- The `keymaster` partition image: ELF64, 8 program headers, first segment
  `0x200` bytes, hash segment at `0x1000` of size `0x1a28`, highest segment end
  `0x35e69`. Assembling it the same way as a vendor `.mdt`/`.bNN` set yields a
  208,631-byte contiguous image.

## 6. How the contracts were recovered

For readers who want to repeat or extend the analysis. No proprietary bytes
or disassembly listings are kept in this repository; offsets quoted in
chapters refer to the exact files hashed above.

1. **Kernel-side ABI** `[G]`: read directly from the pinned source
   (`qseecom.h`, `qseecomi.h`, `qseecom.c`, the FPC platform driver).
2. **HAL call sites** `[S]`: static analysis of
   `android.hardware.biometrics.fingerprint@2.1-service.fpc` (QSEECom session
   setup, the 64-byte request/response wrapper, the sensor/bio/auth command
   encoders, the enrollment and identify loops, the Keymaster wrapped-key
   request).
3. **TA dispatchers** `[S]`: the dynamic symbol table of
   `fpctzappfingerprint` names the module registry and handlers
   (`fpc_device_init`, `fpc_algo_identify_update`,
   `fpc_check_enrollment_allowance`, `fpc_ta_hw_auth_unwrap_key`, …), which
   fixes command numbers, buffer sizes and result semantics.
4. **Keymaster/Gatekeeper** `[S]`: the `keymaster` partition image and
   `libkeymasterdeviceutils.so` give the version handshake, the HMAC sharing
   commands, the Gatekeeper fixed-field layout and the storage path.
5. **RPMB listener** `[S]` `[T]`: stock `librpmb.so` plus LK's open
   implementation for the frame conventions.
6. **On hardware** `[M]`: each recovered step was then exercised in isolation
   on a dedicated lab unit (USB-root disposable boots, UART logs, one-shot
   credential operations with durable receipts) before the daily unit.
   Measured values that disagreed with static expectations (RPMB read length
   in payload blocks, RW field values, FPC-before-Keymaster ordering) are the
   ones recorded in fingerprint.md.

## 7. Not yet pinned

- The Google-published SHA-256 for the factory image was read from a
  third-party mirror listing; the download hash above was computed locally and
  matches the filename prefix, but the developers.google.com page itself is
  JavaScript-rendered and was not archived on 2026-09-14 (Wayback Machine was
  offline).
- Sargo's `vendor.img` and `vendor_b` differ from `.002` only by build
  identity as far as the 16 fingerprint files and the libraries above are
  concerned; a whole-filesystem diff between `.002`, `.006` and `.008` has not
  been done.
- Google's OTA package for `.008` was not downloaded or hashed.

## 8. Verify it yourself

```sh
# 1. Factory image and its contents
curl -O https://dl.google.com/dl/android/aosp/sargo-sp2a.220505.008-factory-071e368a.zip
sha256sum sargo-sp2a.220505.008-factory-071e368a.zip     # 071e368a…37f1
unzip -j sargo-sp2a.220505.008-factory-071e368a.zip '*/image-sargo-sp2a.220505.008.zip'
unzip image-sargo-sp2a.220505.008.zip boot.img dtbo.img vendor.img android-info.txt

# 2. Shipped kernel version (boot v2 header: kernel at page 1, LZ4)
python3 -c "import struct;b=open('boot.img','rb').read();ks,ps=struct.unpack_from('<I',b,8)[0],struct.unpack_from('<I',b,36)[0];open('kernel.lz4','wb').write(b[ps:ps+ks])"
lz4 -d kernel.lz4 Image && grep -a -o 'Linux version 4.9.[^ ]*' Image

# 3. Fingerprint node in the shipped overlays
python3 - <<'PY'
import struct,subprocess
b=open('dtbo.img','rb').read(); _,_,_,esz,n,eoff,_,_=struct.unpack_from('>8I',b,0)
for i in range(n):
    sz,off=struct.unpack_from('>II',b,eoff+i*esz); open(f'o{i}.dtb','wb').write(b[off:off+sz])
    s=subprocess.run(['dtc','-I','dtb','-O','dts','-q',f'o{i}.dtb'],capture_output=True,text=True).stdout
    print(i,[l.strip() for l in s.splitlines() if 'model =' in l][:1],'fpc,fpc1020' in s)
PY

# 4. Firmware hashes from Google's vendor image
simg2img vendor.img vendor.raw
debugfs -R 'cat firmware/fpctzappfingerprint.mbn' vendor.raw | sha256sum   # e947fd8b…97e8

# 5. Kernel source files
sh vendor/kernel-msm-ab4493f31457eea175568b18b8300d4d12aaeea8/verify.sh
```
