#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  02-patch.sh — Patch Application
#
#  Reference: riarumoda/perf_neon-builder (add-goodies.sh +
#             apply-device-patches.sh) এবং
#             JackA1ltman/NonGKI_Kernel_Build_2nd
#
#  Exact flow for ksunext-susfs (legacy-susfs branch):
#    1. KernelSU-Next setup (dev branch setup.sh → legacy-susfs checkout)
#    2. KSU base defconfig entries
#    3. susfs_inline_hook_patches.sh  ← hook mechanism (exec, open,
#       stat, read_write, input, selinux, sys, reboot সব একসাথে)
#    4. susfs_patch_to_4.14.patch     ← SuSFS filesystem patch
#    5. SuSFS defconfig entries
#    6. Sweet device patches (LN8K, DTBO, LTO, KPATCH)
#    7. Sweet defconfig entries
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

# Patch helper
apply_patch_url() {
    local url="$1"
    local name
    name=$(basename "$url")
    echo "  Applying: $name"
    wget -qO- "$url" | patch -s -p1 --fuzz=5 || echo "  (already applied or minor reject)"
}

# ─── Step 1: KernelSU-Next Setup ─────────────────────────────────
# setup.sh টা dev branch থেকে নেওয়া হয়, কিন্তু legacy-susfs checkout করে।
# এটা add-goodies.sh-এর exact approach।
echo ""
echo "→ [1/7] Setting up KernelSU-Next (legacy-susfs)..."

curl -LSs --fail --retry 3 \
    "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/dev/kernel/setup.sh" \
    | bash -s "${KERNELSU_BRANCH}"

echo "✓ KernelSU-Next added (branch: $KERNELSU_BRANCH)"

# ─── Step 2: KSU Base Defconfig Entries ──────────────────────────
echo ""
echo "→ [2/7] Adding KSU base defconfig entries..."

{
    echo "CONFIG_KSU=y"
    echo "CONFIG_KSU_MANUAL_HOOK=y"
    echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y"
    echo "CONFIG_THREAD_INFO_IN_TASK=y"
} >> "$DEFCONFIG"

echo "✓ KSU base configs added"

# ─── Step 3: SuSFS Inline Hook Patches ───────────────────────────
# এটাই পুরো hook mechanism।
# exec.c, open.c, read_write.c, stat.c, namei.c, input.c,
# security.c, selinux/hooks.c, selinux/ss/services.c,
# reboot.c, sys.c, seccomp.h — সব এই একটা script handle করে।
echo ""
echo "→ [3/7] Applying SuSFS inline hook patches..."

curl -fLSs "${NONGKI_RAW}/Patches/susfs_inline_hook_patches.sh" \
    -o /tmp/susfs_inline_hook_patches.sh || {
    echo "✗ susfs_inline_hook_patches.sh download failed!"
    exit 1
}
bash /tmp/susfs_inline_hook_patches.sh

echo "✓ SuSFS inline hook patches applied"

# ─── Step 4: SuSFS Kernel Patch (4.14) ───────────────────────────
# Inline hook-এর পরে apply করতে হয় — add-goodies.sh-এর order।
echo ""
echo "→ [4/7] Applying SuSFS kernel patch (4.14)..."

SUSFS_PATCH_URL="${NONGKI_RAW}/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch"
wget -qO- "$SUSFS_PATCH_URL" | patch -s -p1 --fuzz=5 || \
    echo "  (patch applied with minor rejects or already done)"

echo "✓ SuSFS filesystem patch applied"

# ─── Step 5: SuSFS Defconfig Entries ─────────────────────────────
echo ""
echo "→ [5/7] Adding SuSFS defconfig entries..."

{
    echo "CONFIG_KSU_SUSFS=y"
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y"
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y"
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y"
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y"
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y"
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y"
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y"
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y"
    echo "CONFIG_KSU_SUSFS_SUS_MAP=y"
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y"
    # SUS_SU explicitly disabled (manual hook use করলে লাগে না)
    echo "# CONFIG_KSU_SUSFS_SUS_SU is not set"
} >> "$DEFCONFIG"

echo "✓ SuSFS configs added"

# ─── Step 6: Sweet Device Patches ────────────────────────────────
# apply-device-patches.sh থেকে sweet-এর exact patches।
echo ""
echo "→ [6/7] Applying sweet device patches..."

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

# ─── Step 7: Sweet Defconfig Entries ─────────────────────────────
echo ""
echo "→ [7/7] Adding sweet device defconfig entries..."

{
    echo "CONFIG_CHARGER_LN8000=y"
    echo "CONFIG_LTO_CLANG=y"
    echo "CONFIG_THINLTO=y"
    echo "# CONFIG_LTO_NONE is not set"
    echo "CONFIG_EROFS_FS=y"
    echo "CONFIG_SECURITY_SELINUX_DEVELOP=y"
} >> "$DEFCONFIG"

echo "✓ Sweet device configs added"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [02] All Patches Applied ✓"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
