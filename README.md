# Sweet Kernel Builder

Automated kernel build pipeline.  
Builds two variants on every manual trigger, packages them with AnyKernel3,  
and publishes a GitHub Release automatically on success.

> Inspired by [riarumoda/perf_neon-builder](https://github.com/riarumoda/perf_neon-builder).

## Variants

| Variant | Description |
|---------|-------------|
| `stock` | Close-to-stock kernel — device patches only |
| `ksu` | ReSukiSU + SuSFS on top of stock |

The stock variant includes only the patches required for the device to work
correctly — LN8K charging IC support, DTBO fixes, LTO, and a QCA WiFi driver
bug fix. No extra features, no bloat.

## Device

| | |
|---|---|
| **Device** | Redmi Note 10 Pro / Pro Max |
| **Codename** | sweet / sweetin |
| **Kernel** | 4.14 \| arm64 |
| **Source** | [yurixen/android_kernel_xiaomi_sm6150 @ sixteen-qpr2](https://github.com/yureixen/android_kernel_xiaomi_sm6150/tree/sixteen-qpr2) |
| **Compiler** | LineageOS Clang r416183b |

## Usage

1. Fork this repo
2. **Actions → Build Sweet Kernel → Run workflow**
3. Both variants build in parallel
4. GitHub Release is created automatically on success

## Flash Instructions

1. Boot into custom recovery (TWRP / OrangeFox)
2. Flash the zip for your variant
3. Reboot

> [!CAUTION]
> Always backup your boot image before flashing!

## Credits

**Kernel Source**
- [PixelOS-Devices](https://github.com/PixelOS-Devices/android_kernel_xiaomi_sm6150) — kernel source base (sixteen-qpr2)

**Patches**
- [crdroidandroid](https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150) — LN8K charging IC patches
- [tbyool](https://github.com/tbyool/android_kernel_xiaomi_sm6150) — LN8K charging IC patches (extended)
- [xiaomi-sm6150](https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150) — DTBO patches
- [TheSillyOk](https://github.com/TheSillyOk/kernel_ls_patches) — LTO & kpatch fix for 4.14
- [JackA1ltman](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd) — SuSFS inline hook script & SuSFS 4.14 patch

**Projects**
- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) — KernelSU implementation with 4.x support
- [simonpunk](https://github.com/simonpunk/susfs4ksu) — SuSFS
- [LineageOS](https://github.com/LineageOS) — Clang r416183b & GCC toolchains
- [osm0sis](https://github.com/osm0sis/AnyKernel3) — AnyKernel3

**Inspiration**
- [riarumoda/perf_neon-builder](https://github.com/riarumoda/perf_neon-builder) — build pipeline structure & approach

## License

GPL-2.0 — See [LICENSE](LICENSE)
