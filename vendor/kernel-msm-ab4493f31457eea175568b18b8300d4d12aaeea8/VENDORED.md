# Vendored kernel sources

Source: `https://android.googlesource.com/kernel/msm`, branch
`android-msm-bonito-4.9-android12L`, commit
`ab4493f31457eea175568b18b8300d4d12aaeea8` (committed 2022-03-08, kernel tags
`android-12.1.0_r0.17` and `android-12.1.0_r0.23`). This is the kernel source
tree Google publishes for the Pixel 3a / 3a XL Android 12L builds; see
`provenance.md` §3 for how the build maps to this commit.

Licence: GPL-2.0 (headers in each file). Copied byte-for-byte; no edits.

| File | Why it is here |
| --- | --- |
| `arch/arm64/boot/dts/google/sdm670-b4s4-fingerprint.dtsi` | the fingerprint platform node and its pinctrl states |
| `arch/arm64/boot/dts/google/sdm670-b4s4-common.dtsi` | proves the fingerprint dtsi is included in the sargo/bonito board DT |
| `arch/arm64/boot/dts/qcom/sdm670.dtsi` | QSEECOM node, secure-app region and reserved memory for QSEE |
| `arch/arm64/configs/bonito_defconfig` | `CONFIG_QSEECOM=y`, `CONFIG_FPC_FINGERPRINT=y` |
| `build.config.bonito` | ties `bonito_defconfig` to the build |
| `drivers/input/misc/fpc_fingerprint/*` | the stock FPC platform driver (electrical control and IRQ only) |
| `include/uapi/linux/qseecom.h` | the `/dev/qseecom` ioctl ABI Android userspace uses |
| `include/soc/qcom/qseecomi.h` | the QSEOS command IDs and SCM request layouts the kernel sends to secure firmware |

Verify against Google's server:

```sh
./verify.sh
```

`SHA256SUMS` lists the hashes of the copies; `verify.sh` re-downloads each
file at the pinned commit and compares.
