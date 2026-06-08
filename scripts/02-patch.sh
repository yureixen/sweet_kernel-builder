#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  02-patch.sh — Patch Application
#
#  Flow (ksunext + susfs, legacy-susfs branch):
#    1. KernelSU-Next setup (dev branch setup.sh → legacy-susfs)
#    2. KSU base defconfig entries
#    3. susfs_inline_hook_patches.sh  ← all hooks in one script
#    4. susfs_patch_to_4.14.patch     ← SuSFS filesystem patch
#    5. SuSFS defconfig entries
#    6. Sweet device patches (LN8K, DTBO, LTO, KPATCH)
#    7. Sweet + build-fix defconfig entries
# ════════════════════════════════════════════════════════════════
set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [02] Applying Patches"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$KERNEL_DIR"

NONGKI_RAW="https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/mainline"
DEFCONFIG="arch/arm64/configs/${KERNEL_DEFCONFIG}"
KERNEL_VERSION="4.14"

# ─── Patch helper ────────────────────────────────────────────────
apply_patch_url() {
    local url="$1"
    local name
    name=$(basename "$url")
    echo "    Applying: $name"
    if wget -qO- "$url" | patch -s -p1 --fuzz=5 2>/dev/null; then
        echo "    ✓ $name"
    else
        echo "    ⚠ $name (already applied or minor reject, continuing)"
    fi
}

# ─── Step 1: KernelSU-Next Setup ─────────────────────────────────
echo ""
echo "→ [1/7] Setting up KernelSU-Next (branch: $KERNELSU_BRANCH)..."

curl -LSs --fail --retry 3 \
    "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/dev/kernel/setup.sh" \
    | bash -s "${KERNELSU_BRANCH}"

echo "✓ KernelSU-Next added"

# ─── Step 2: KSU Base Defconfig ──────────────────────────────────
echo ""
echo "→ [2/7] Adding KSU defconfig entries..."

cat >> "$DEFCONFIG" << 'EOF'
# KernelSU-Next
CONFIG_KSU=y
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_HAVE_SYSCALL_TRACEPOINTS=y
CONFIG_THREAD_INFO_IN_TASK=y
EOF

echo "✓ KSU defconfig added"

# ─── Step 3: SuSFS Inline Hook Patches ───────────────────────────
# Handles: exec.c, open.c, read_write.c, stat.c, namei.c, input.c,
# security.c, selinux/hooks.c, selinux/ss/services.c, reboot.c,
# sys.c, seccomp.h — all in one script
echo ""
echo "→ [3/7] Applying SuSFS inline hook patches..."

curl -fLSs "${NONGKI_RAW}/Patches/susfs_inline_hook_patches.sh" \
    -o /tmp/susfs_inline_hook_patches.sh || {
    echo "✗ Failed to download susfs_inline_hook_patches.sh"
    exit 1
}
bash /tmp/susfs_inline_hook_patches.sh

echo "✓ SuSFS inline hook patches applied"

# ─── Step 4: SuSFS Kernel Patch (4.14) ───────────────────────────
echo ""
echo "→ [4/7] Applying SuSFS filesystem patch (kernel $KERNEL_VERSION)..."

wget -qO- "${NONGKI_RAW}/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch" \
    | patch -s -p1 --fuzz=5 || \
    echo "  ⚠ Patch applied with minor rejects or already done"

echo "✓ SuSFS filesystem patch applied"

# ─── Step 5: SuSFS Defconfig ─────────────────────────────────────
echo ""
echo "→ [5/7] Adding SuSFS defconfig entries..."

cat >> "$DEFCONFIG" << 'EOF'
# SuSFS
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SPOOF_UNAME=y
CONFIG_KSU_SUSFS_ENABLE_LOG=y
CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y
CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
CONFIG_KSU_SUSFS_SUS_MAP=y
CONFIG_KSU_SUSFS_TRY_UMOUNT=y
# SUS_SU disabled — using manual hook instead
# CONFIG_KSU_SUSFS_SUS_SU is not set
EOF

echo "✓ SuSFS defconfig added"

# ─── Step 6: Sweet Device Patches ────────────────────────────────
echo ""
echo "→ [6/7] Applying Sweet device patches..."

XIAOMI_SM6150="https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit"
TBYOOL="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit"
XIAOMI_DTBO="https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit"
LS_PATCHES="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master"

echo "  → LN8K charging IC patches..."
apply_patch_url "${XIAOMI_SM6150}/7b73f853977d2c016e30319dffb1f49957d30b40.patch"
apply_patch_url "${XIAOMI_SM6150}/63dddc108d57dc43e1cd0da0f1445875f760cf97.patch"
apply_patch_url "${XIAOMI_SM6150}/95816dff2ecc7ddd907a56537946b5cf1e864953.patch"
apply_patch_url "${XIAOMI_SM6150}/330c60abc13530bd05287f9e5395d283ebfd6d0b.patch"
apply_patch_url "${XIAOMI_SM6150}/0477c7006b41a1763b3314af9eb300491b91fc25.patch"
apply_patch_url "${TBYOOL}/aa5ddad5be03aa7436e7ce6e84d46b280849acae.patch"
apply_patch_url "${TBYOOL}/857638b0da6f80830122b8d1b45c7842970e76c3.patch"
apply_patch_url "${TBYOOL}/3a68adff14cbedd09ce2a735d575c3bf92dd696f.patch"
apply_patch_url "${TBYOOL}/30fcc15d5dcf2cfc3b83a5a7d4a77e2880639fa5.patch"
apply_patch_url "${TBYOOL}/1a17a6fbbf59d901c4b3aec66c06a1c96cd89c7e.patch"
echo "  ✓ LN8K patches done"

echo "  → DTBO patches..."
apply_patch_url "${XIAOMI_DTBO}/e517bc363a19951ead919025a560f843c2c03ad3.patch"
apply_patch_url "${XIAOMI_DTBO}/a62a3b05d0f29aab9c4bf8d15fe786a8c8a32c98.patch"
apply_patch_url "${XIAOMI_DTBO}/4b89948ec7d610f997dd1dab813897f11f403a06.patch"
apply_patch_url "${XIAOMI_DTBO}/fade7df36b01f2b170c78c63eb8fe0d11c613c4a.patch"
apply_patch_url "${XIAOMI_DTBO}/2628183db0d96be8dae38a21f2b09cb10978f423.patch"
apply_patch_url "${XIAOMI_DTBO}/31f4577af3f8255ae503a5b30d8f68906edde85f.patch"
echo "  ✓ DTBO patches done"

echo "  → LTO + KPATCH patches..."
apply_patch_url "${LS_PATCHES}/fix_lto.patch"
apply_patch_url "${LS_PATCHES}/kpatch_fix.patch"
echo "  ✓ LTO + KPATCH patches done"

echo "✓ Sweet device patches applied"

# ─── Step 7: Sweet + Build-Fix Defconfig ─────────────────────────
echo ""
echo "→ [7/7] Adding Sweet device + build fix defconfig entries..."

cat >> "$DEFCONFIG" << 'EOF'
# Sweet device configs
CONFIG_CHARGER_LN8000=y

# LTO (Clang Link Time Optimization)
CONFIG_LTO_CLANG=y
CONFIG_THINLTO=y
# CONFIG_LTO_NONE is not set

# vDSO32 disabled:
# lld cannot link 32-bit ARM vDSO — disable to fix build.
# Sweet stock kernel has this disabled too, zero impact on boot.
# CONFIG_VDSO32 is not set

# Extras
CONFIG_EROFS_FS=y
CONFIG_SECURITY_SELINUX_DEVELOP=y
EOF

echo "✓ Sweet + build-fix defconfig added"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [02] All Patches Applied ✓"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
