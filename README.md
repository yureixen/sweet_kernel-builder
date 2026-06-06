# sweet_kernel-builder

Automated kernel build pipeline for **Redmi Note 10 Pro (sweet)** — Kernel 4.14, arm64.

## Features

- **KernelSU-Next** (`legacy-susfs` branch) — root solution
- **SuSFS** (4.14 kernel patch) — kernel-level root hiding
- **Neutron Clang** — modern Clang toolchain
- GitHub Actions automated build

## Quick Start

1. Fork this repo to your GitHub account
2. Go to **Actions** tab → **Build Sweet Kernel** → **Run workflow**
3. Download the zip from **Artifacts** when done
4. Flash via TWRP or similar recovery

## File Structure

```
sweet_kernel-builder/
├── .github/
│   └── workflows/
│       └── build.yml       ← GitHub Actions workflow
├── scripts/
│   ├── 01-setup.sh         ← Toolchain + kernel clone
│   ├── 02-patch.sh         ← KSU-Next + SuSFS patches
│   └── 03-build.sh         ← Compile + AnyKernel3 zip
├── config.env              ← All build variables (edit here)
├── LICENSE
└── README.md
```

## Configuration

Edit `config.env` to change any build settings:

| Variable | Current Value | Description |
|---|---|---|
| `KERNEL_REPO` | yureixen/android_kernel_xiaomi_sm6150 | Kernel source |
| `KERNEL_BRANCH` | sixteen-qpr2 | Source branch |
| `KERNEL_DEFCONFIG` | sweet_defconfig | Device defconfig |
| `KERNELSU_BRANCH` | legacy-susfs | KernelSU-Next branch |
| `AK3_BRANCH` | sweet | AnyKernel3 branch |

## Credits

- **riarumoda** — perf_neon-builder (inspiration for build structure)
- **JackA1ltman** — NonGKI_Kernel_Build_2nd (hook scripts, SuSFS patches)
- **KernelSU-Next** — rifsxd
- **SuSFS** — simonpunk
- **Neutron Clang** — Neutron-Toolchains

## License

GPL-2.0 — See [LICENSE](LICENSE)
