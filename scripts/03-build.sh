#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  03-build.sh — Kernel Compilation + AnyKernel3 Packaging
#
#  Key fixes vs original:
#    · LD=ld.lld  → fixes vDSO gold linker error
#    · CROSS_COMPILE_COMPAT  → proper 32-bit compat toolchain
#    · HOSTLD=ld.lld  → host linker also uses lld
#    · LLVM=1  → full LLVM toolchain (no mixed GNU/LLVM issues)
#    · LLVM_IAS=1  → LLVM integrated assembler
# ════════════════════════════════════════════════════════════════
set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [03] Building Kernel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$KERNEL_DIR"

# Add Neutron Clang to PATH
export PATH="$CLANG_BIN:$PATH"

JOBS=$(nproc --all)
OUT="$KERNEL_OUT"

# Print build info
echo ""
echo "  Kernel dir : $KERNEL_DIR"
echo "  Defconfig  : $KERNEL_DEFCONFIG"
echo "  Clang      : $(clang --version | head -1)"
echo "  LLD        : $(ld.lld --version | head -1)"
echo "  Jobs       : $JOBS"
echo "  Output     : $OUT"

# ─── Make Arguments ──────────────────────────────────────────────
# LLVM=1 → use full LLVM toolchain (clang, lld, llvm-ar, etc.)
# LLVM_IAS=1 → use LLVM integrated assembler (faster, better compat)
# LD=ld.lld → explicitly use lld linker (fixes gold linker errors)
# CROSS_COMPILE_COMPAT → 32-bit ARM for compat syscalls (not vDSO32)
MAKE_ARGS=(
    -j"$JOBS"
    O="$OUT"
    ARCH=arm64
    SUBARCH=arm64
    LLVM=1
    LLVM_IAS=1
    CC=clang
    LD=ld.lld
    AR=llvm-ar
    NM=llvm-nm
    OBJCOPY=llvm-objcopy
    OBJDUMP=llvm-objdump
    READELF=llvm-readelf
    STRIP=llvm-strip
    HOSTCC=clang
    HOSTCXX=clang++
    HOSTLD=ld.lld
    HOSTAR=llvm-ar
    CROSS_COMPILE=aarch64-linux-gnu-
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
)

# ─── Step 1: Make defconfig ──────────────────────────────────────
echo ""
echo "→ [1/3] Generating defconfig..."

make "${MAKE_ARGS[@]}" "$KERNEL_DEFCONFIG"

echo "✓ Defconfig generated"

# ─── Step 2: Compile ─────────────────────────────────────────────
echo ""
echo "→ [2/3] Compiling kernel..."
echo "  (This will take a while...)"

START_TIME=$(date +%s)

# Build kernel image + dtbo
# Image.gz-dtb = compressed kernel + appended DTBs (required for sweet)
set +e
make "${MAKE_ARGS[@]}" Image.gz-dtb dtbo.img 2>&1 | tee /tmp/build.log
BUILD_EXIT=${PIPESTATUS[0]}
set -e

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS=$(( ELAPSED % 60 ))

echo ""
echo "  Build time: ${MINUTES}m ${SECONDS}s"

# ─── Verify Output ───────────────────────────────────────────────
IMAGE_GZ_DTB="$OUT/arch/arm64/boot/Image.gz-dtb"
DTBO="$OUT/arch/arm64/boot/dtbo.img"

if [ ! -f "$IMAGE_GZ_DTB" ]; then
    echo ""
    echo "✗ Build FAILED — Image.gz-dtb not found!"
    echo ""
    echo "  Last 40 lines of build log:"
    echo "  ─────────────────────────────────"
    tail -40 /tmp/build.log
    exit 1
fi

echo "✓ Kernel compiled successfully"
echo "  Image.gz-dtb : $(du -h "$IMAGE_GZ_DTB" | cut -f1)"
[ -f "$DTBO" ] && echo "  dtbo.img     : $(du -h "$DTBO" | cut -f1)"

# ─── Step 3: Package AnyKernel3 ──────────────────────────────────
echo ""
echo "→ [3/3] Packaging AnyKernel3 zip..."

cd "$AK3_DIR"

# Clean old files
rm -f Image.gz-dtb Image.gz dtb dtbo.img *.zip

# Copy kernel image
cp "$IMAGE_GZ_DTB" "$AK3_DIR/Image.gz-dtb"
[ -f "$DTBO" ] && cp "$DTBO" "$AK3_DIR/dtbo.img"

# Build zip
BUILD_DATE=$(date +'%Y%m%d-%H%M')
ZIP_NAME="sweet-kernel-KSU-SuSFS-${BUILD_DATE}.zip"

zip -r9 "$ZIP_NAME" . \
    -x ".git/*"    \
    -x "*.zip"     \
    -x "README.md" \
    -x "*.sh"

ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
echo "✓ AnyKernel3 zip created"
echo "  File : $ZIP_NAME"
echo "  Size : $ZIP_SIZE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [03] Build Complete ✓"
echo "  Output : $AK3_DIR/$ZIP_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
