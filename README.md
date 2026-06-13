# Sweet Kernel Builder

Automated kernel build pipeline.

## Variants

| Variant | Description |
|---------|-------------|
| `stock` | Stock — device patches only |
| `ksu` | ReSukiSU + SuSFS + device patches |

## Compatibility
**Currently supported device**
- Redmi Note 10 Pro/Pro Max ([sweet](https://download.lineageos.org/devices/sweet/builds))

## Credits

**Patches & buildscript**
- [crdroidandroid](https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150) — LN8K charging IC patches
- [tbyool](https://github.com/tbyool/android_kernel_xiaomi_sm6150) — LN8K charging IC patches (extended)
- [xiaomi-sm6150](https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150) — DTBO patches
- [TheSillyOk](https://github.com/TheSillyOk/kernel_ls_patches) — LTO & kpatch fix for 4.14
- [JackA1ltman](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd) — SuSFS inline hook script & SuSFS 4.14 patch

**Projects**
- [PixelOS-Devices](https://github.com/PixelOS-Devices/android_kernel_xiaomi_sm6150) — for kernel source
- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) — KernelSU implementation with 4.x support

---

> Inspired by [riarumoda/perf_neon-builder](https://github.com/riarumoda/perf_neon-builder)
