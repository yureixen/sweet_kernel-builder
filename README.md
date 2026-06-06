# sweet_kernel-builder

Automated kernel build pipeline for **Redmi Note 10 Pro (sweet)** — Kernel 4.14, arm64.

## Features

- **KernelSU-Next** (`legacy-susfs` branch) — root solution
- **SuSFS** (4.14 kernel patch) — kernel-level root hiding
- GitHub Actions automated build

## Quick Start

1. Fork this repo to your GitHub account
2. Go to **Actions** tab → **Build Sweet Kernel** → **Run workflow**
3. Download the zip from **Artifacts** when done
4. Flash via TWRP or similar recovery


## Credits

- **riarumoda** — perf_neon-builder (inspiration for build structure)
- **JackA1ltman** — NonGKI_Kernel_Build_2nd (hook scripts, SuSFS patches)
- **KernelSU-Next** — rifsxd
- **SuSFS** — simonpunk
- **Neutron Clang** — Neutron-Toolchains

## License

GPL-2.0 — See [LICENSE](LICENSE)
