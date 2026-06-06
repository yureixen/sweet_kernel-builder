#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  02-patch.sh — Patch Application
#
#  Order (important, don't change):
#    1. KernelSU-Next setup (legacy-susfs branch)
#    2. KSU Manual hook patches (kprobe disabled on sweet/4.14)
#    3. SuSFS kernel patch (4.14)
#    4. SuSFS inline hook patches (for manual hook compatibility)
#    5. Defconfig update (KSU + SuSFS configs enable)
# ════════════════════════════════════════════════════════════════
set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [02] Applying Patches"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$KERNEL_DIR"

# ─── Step 1: KernelSU-Next Setup ─────────────────────────────────
echo ""
echo "→ [1/5] Setting up KernelSU-Next (branch: $KERNELSU_BRANCH)..."

curl -LSs \
    "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/${KERNELSU_BRANCH}/kernel/setup.sh" \
    | bash -s "${KERNELSU_BRANCH}"

echo "✓ KernelSU-Next added to kernel tree"

# ─── Step 2: KSU Manual Hook Patches ─────────────────────────────
# Sweet/4.14-e CONFIG_KPROBES disabled, tai manual hook lagbe.
# JackA1ltman/NonGKI_Kernel_Build_2nd theke syscall hook script download.
echo ""
echo "→ [2/5] Applying KSU manual hook patches..."

NONGKI_RAW="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/syscall_hook_patches.sh"

curl -LSs "${NONGKI_RAW}/Patches/patch-ksu-hooks-4.14.sh" -o /tmp/ksu-hooks.sh 2>/dev/null || \
curl -LSs "${NONGKI_RAW}/Bin/patch-ksu-hooks.sh" -o /tmp/ksu-hooks.sh 2>/dev/null || {
    echo "⚠ Hook script URL may have changed."
    echo "  https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/syscall_hook_patches.sh"
    echo "  Download the 4.14 hook script manually and place it at: /tmp/ksu-hooks.sh"
    exit 1
}

bash /tmp/ksu-hooks.sh
echo "✓ KSU manual hooks applied"

# ─── Step 3: SuSFS Kernel Patch (4.14) ───────────────────────────
# Primary source: simonpunk's gitlab (official SuSFS)
echo ""
echo "→ [3/5] Applying SuSFS kernel patches (4.14)..."

SUSFS_RAW="https://gitlab.com/simonpunk/susfs4ksu/-/raw/kernel-4.14/kernel_patches"

# Patch 1: Enable SuSFS in KSU
curl -LSs "${SUSFS_RAW}/10_enable_susfs_for_ksu.patch" -o /tmp/susfs-ksu.patch
echo "  Applying 10_enable_susfs_for_ksu.patch..."
patch -p1 --forward < /tmp/susfs-ksu.patch || echo "  (already applied or minor reject — continuing)"

# Patch 2: Main SuSFS filesystem patch
curl -LSs "${SUSFS_RAW}/50_add_susfs_in_fs-4.14.patch" -o /tmp/susfs-fs.patch
echo "  Applying 50_add_susfs_in_fs-4.14.patch..."
patch -p1 --forward < /tmp/susfs-fs.patch || echo "  (already applied or minor reject — continuing)"

echo "✓ SuSFS kernel patches applied"

# ─── Step 4: SuSFS Inline Hook Patches ───────────────────────────
# Manual hook use korle susfs-er inline hook patches o lagbe.
# JackA1ltman/NonGKI_Kernel_Build_2nd theke download.
echo ""
echo "→ [4/5] Applying SuSFS inline hook patches..."

curl -LSs "${NONGKI_RAW}/Patches/susfs_inline_hook_patches.sh" -o /tmp/susfs-inline.sh 2>/dev/null || {
    echo "⚠ Inline hook script URL may have changed."
    echo "  Check: https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh"
    exit 1
}

bash /tmp/susfs-inline.sh
echo "✓ SuSFS inline hook patches applied"

# ─── Step 5: Defconfig Update ────────────────────────────────────
echo ""
echo "→ [5/5] Updating defconfig for KSU + SuSFS..."

DEFCONFIG_PATH="arch/arm64/configs/${KERNEL_DEFCONFIG}"

# KernelSU core
scripts/config --file "$DEFCONFIG_PATH" -e CONFIG_KSU

# SuSFS features
scripts/config --file "$DEFCONFIG_PATH" \
    -e CONFIG_KSU_SUSFS \
    -e CONFIG_KSU_SUSFS_SUS_PATH \
    -e CONFIG_KSU_SUSFS_SUS_MOUNT \
    -e CONFIG_KSU_SUSFS_SUS_KSTAT \
    -e CONFIG_KSU_SUSFS_SUS_OVERLAYFS \
    -e CONFIG_KSU_SUSFS_TRY_UMOUNT \
    -e CONFIG_KSU_SUSFS_SPOOF_UNAME \
    -e CONFIG_KSU_SUSFS_ENABLE_LOG \
    -e CONFIG_KSU_SUSFS_OPEN_REDIRECT

# SUS_SU disable (manual hook use korle SUS_SU lagbe na)
scripts/config --file "$DEFCONFIG_PATH" -d CONFIG_KSU_SUSFS_SUS_SU

echo "✓ Defconfig updated"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [02] Patches Applied ✓"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
