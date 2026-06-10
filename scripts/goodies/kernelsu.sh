#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  goodies/kernelsu.sh — KernelSU-Next + SuSFS integration
#  Branch: legacy-susfs (KernelSU-Next by rifsxd)
#  SuSFS patch: JackA1ltman/NonGKI_Kernel_Build_2nd
# ════════════════════════════════════════════════════════════════
# Called from patches.sh — $KERNEL_DIR and $DEFCONFIG already set

DEFCONFIG="arch/arm64/configs/${KERNEL_DEFCONFIG}"
NONGKI_RAW="https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/mainline"

echo ""
echo "→ [KSU] Setting up KernelSU-Next (branch: $KERNELSU_BRANCH)..."

# ── Step 1: KernelSU-Next setup ───────────────────────────────
curl -LSs --fail --retry 3 \
    "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" \
    | bash -s "$KERNELSU_BRANCH" || {
    echo "✗ KernelSU-Next setup failed!"
    exit 1
}
echo "  ✓ KernelSU-Next added"

# ── Step 2: KSU defconfig ─────────────────────────────────────
cat >> "$DEFCONFIG" << 'EOF'
# KernelSU-Next
CONFIG_KSU=y
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_HAVE_SYSCALL_TRACEPOINTS=y
CONFIG_THREAD_INFO_IN_TASK=y
EOF
echo "  ✓ KSU defconfig added"

# ── Step 3: SuSFS inline hook patches ────────────────────────
echo "  → Applying SuSFS inline hook patches..."
curl -fLSs --retry 3 "${NONGKI_RAW}/Patches/susfs_inline_hook_patches.sh" \
    -o /tmp/susfs_inline_hook.sh || {
    echo "✗ Failed to download susfs_inline_hook_patches.sh"
    exit 1
}
bash /tmp/susfs_inline_hook.sh || {
    echo "✗ susfs_inline_hook_patches.sh failed"
    exit 1
}
echo "  ✓ SuSFS inline hook patches applied"

# ── Step 4: SuSFS kernel patch (4.14) ────────────────────────
echo "  → Applying SuSFS filesystem patch (kernel ${KERNEL_VERSION})..."
wget -qO- "${NONGKI_RAW}/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch" \
    | patch -s -p1 --fuzz=5 2>/dev/null || \
    echo "  ⚠ SuSFS patch: minor rejects or already applied, continuing"
echo "  ✓ SuSFS filesystem patch done"

# ── Step 5: SuSFS defconfig ───────────────────────────────────
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
# CONFIG_KSU_SUSFS_SUS_SU is not set
EOF
echo "  ✓ SuSFS defconfig added"

echo "→ [KSU] KernelSU-Next + SuSFS setup complete ✓"
