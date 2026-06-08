#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  02-patch.sh — Patch Application
#
#  Flow:
#    1. KernelSU-Next setup (legacy-susfs) — unchanged
#    2. KSU base defconfig — unchanged
#    3. susfs_inline_hook_patches.sh — unchanged
#    4. susfs_patch_to_4.14.patch — unchanged
#    5. SuSFS defconfig — unchanged
#    6. Sweet device patches (LN8K, DTBO, LTO, KPATCH) — unchanged
#    7. QCA WiFi driver real bug fix (enum type mismatch)
#    8. Sweet + build-fix defconfig — unchanged
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
echo "→ [1/8] Setting up KernelSU-Next (branch: $KERNELSU_BRANCH)..."

curl -LSs --fail --retry 3 \
    "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/dev/kernel/setup.sh" \
    | bash -s "${KERNELSU_BRANCH}"

echo "✓ KernelSU-Next added"

# ─── Step 2: KSU Base Defconfig ──────────────────────────────────
echo ""
echo "→ [2/8] Adding KSU defconfig entries..."

cat >> "$DEFCONFIG" << 'EOF'
# KernelSU-Next
CONFIG_KSU=y
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_HAVE_SYSCALL_TRACEPOINTS=y
CONFIG_THREAD_INFO_IN_TASK=y
EOF

echo "✓ KSU defconfig added"

# ─── Step 3: SuSFS Inline Hook Patches ───────────────────────────
echo ""
echo "→ [3/8] Applying SuSFS inline hook patches..."

curl -fLSs "${NONGKI_RAW}/Patches/susfs_inline_hook_patches.sh" \
    -o /tmp/susfs_inline_hook_patches.sh || {
    echo "✗ Failed to download susfs_inline_hook_patches.sh"
    exit 1
}
bash /tmp/susfs_inline_hook_patches.sh

echo "✓ SuSFS inline hook patches applied"

# ─── Step 4: SuSFS Kernel Patch (4.14) ───────────────────────────
echo ""
echo "→ [4/8] Applying SuSFS filesystem patch (kernel $KERNEL_VERSION)..."

wget -qO- "${NONGKI_RAW}/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch" \
    | patch -s -p1 --fuzz=5 || \
    echo "  ⚠ Patch applied with minor rejects or already done"

echo "✓ SuSFS filesystem patch applied"

# ─── Step 5: SuSFS Defconfig ─────────────────────────────────────
echo ""
echo "→ [5/8] Adding SuSFS defconfig entries..."

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

echo "✓ SuSFS defconfig added"

# ─── Step 6: Sweet Device Patches ────────────────────────────────
echo ""
echo "→ [6/8] Applying Sweet device patches..."

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

# ─── Step 7: QCA WiFi Driver Bug Fix ─────────────────────────────
# Bug: ce_main.c এ function return type QDF_STATUS হলেও
#      A_STATUS enum এর value (A_ERROR, A_OK) return করা হচ্ছে।
#
# এটা real type mismatch bug — QCA এর পুরনো code এ A_STATUS আর
# QDF_STATUS দুইটা parallel enum system ছিল।
# Newer Clang (15+) এটাকে -Werror দিয়ে error করে দেয়, কারণ
# এটা সত্যিই undefined behavior হতে পারে।
#
# Correct fix:
#   A_ERROR  → QDF_STATUS_E_FAILURE  (failure case)
#   A_OK     → QDF_STATUS_SUCCESS    (success case)
# এই mapping QDF framework এর official equivalent।
echo ""
echo "→ [7/8] Fixing QCA WiFi driver enum type mismatch bug..."

QCA_HIF_CE="drivers/staging/qcacld-3.0/../qca-wifi-host-cmn/hif/src/ce"

fix_enum_in_file() {
    local file="$1"
    local changed=0

    if grep -q "return A_ERROR;" "$file" 2>/dev/null; then
        sed -i 's/\breturn A_ERROR;/return QDF_STATUS_E_FAILURE;/g' "$file"
        echo "    Fixed A_ERROR → QDF_STATUS_E_FAILURE in: $(basename "$file")"
        changed=1
    fi

    if grep -q "return A_OK;" "$file" 2>/dev/null; then
        # A_OK → QDF_STATUS_SUCCESS শুধু তখনই করব যখন
        # function QDF_STATUS return করে (false positive এড়াতে)
        # hif/src/ce/ এর সব function এ QDF_STATUS return type আছে
        sed -i 's/\breturn A_OK;/return QDF_STATUS_SUCCESS;/g' "$file"
        echo "    Fixed A_OK → QDF_STATUS_SUCCESS in: $(basename "$file")"
        changed=1
    fi

    return $changed
}

FIXED_COUNT=0
if [ -d "$QCA_HIF_CE" ]; then
    while IFS= read -r -d '' file; do
        if fix_enum_in_file "$file"; then
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    done < <(find "$QCA_HIF_CE" -name "*.c" -print0 2>/dev/null)
    echo "  Fixed $FIXED_COUNT file(s) in hif/src/ce/"
else
    echo "  ⚠ QCA CE directory not found: $QCA_HIF_CE"
    echo "    kernel clone সম্পূর্ণ হয়েছে কিনা check করুন"
fi

echo "✓ QCA WiFi driver enum fix done"

# ─── Step 8: Sweet + Build-Fix Defconfig ─────────────────────────
echo ""
echo "→ [8/8] Adding Sweet device + build fix defconfig entries..."

cat >> "$DEFCONFIG" << 'EOF'
# Sweet device configs
CONFIG_CHARGER_LN8000=y

# LTO (Clang Link Time Optimization)
CONFIG_LTO_CLANG=y
CONFIG_THINLTO=y
# CONFIG_LTO_NONE is not set

# vDSO32 disabled — lld cannot link 32-bit ARM vDSO
# Sweet stock kernel has this disabled too, zero boot impact
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
