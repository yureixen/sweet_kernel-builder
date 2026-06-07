#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  03-build.sh — Kernel Compilation + AnyKernel3 Packaging
# ════════════════════════════════════════════════════════════════
set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [03] Building Kernel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$KERNEL_DIR"

export PATH="$CLANG_BIN:$PATH"

JOBS=$(nproc --all)
OUT="$KERNEL_OUT"

echo ""
echo "  Kernel dir : $KERNEL_DIR"
echo "  Defconfig  : $KERNEL_DEFCONFIG"
echo "  Clang      : $(clang --version | head -1)"
echo "  Jobs       : $JOBS"

# ─── Make args ───────────────────────────────────────────────────
MAKE_ARGS=(
    -j"$JOBS"
    O="$OUT"
    ARCH=arm64
    SUBARCH=arm64
    CC=clang
    CLANG_TRIPLE=aarch64-linux-gnu-
    CROSS_COMPILE=aarch64-linux-gnu-
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    AR=llvm-ar
    NM=llvm-nm
    OBJCOPY=llvm-objcopy
    OBJDUMP=llvm-objdump
    STRIP=llvm-strip
    HOSTCC=clang
    HOSTCXX=clang++
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
make "${MAKE_ARGS[@]}" Image.gz-dtb dtbo.img 2>&1 | tee /tmp/build.log
END_TIME=$(date +%s)

ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS=$(( ELAPSED % 60 ))
echo "✓ Compilation done in ${MINUTES}m ${SECONDS}s"

# ─── Verify output ───────────────────────────────────────────────
IMAGE_GZ_DTB="$OUT/arch/arm64/boot/Image.gz-dtb"
DTBO="$OUT/arch/arm64/boot/dtbo.img"

if [ ! -f "$IMAGE_GZ_DTB" ]; then
    echo "✗ Image.gz-dtb not found! Build failed."
    echo "  Last 30 lines of build log:"
    tail -30 /tmp/build.log
    exit 1
fi

echo "  Image.gz-dtb : $(du -h "$IMAGE_GZ_DTB" | cut -f1)"
[ -f "$DTBO" ] && echo "  dtbo.img     : $(du -h "$DTBO" | cut -f1)"

# ─── Step 3: Package AnyKernel3 ──────────────────────────────────
echo ""
echo "→ [3/3] Packaging AnyKernel3 zip..."

cd "$AK3_DIR"
rm -f Image.gz-dtb Image.gz dtb dtbo.img *.zip

cp "$IMAGE_GZ_DTB" "$AK3_DIR/Image.gz-dtb"
[ -f "$DTBO" ] && cp "$DTBO" "$AK3_DIR/dtbo.img"

BUILD_DATE=$(date +'%Y%m%d-%H%M')
ZIP_NAME="sweet-kernel-KSU-SuSFS-${BUILD_DATE}.zip"

zip -r9 "$ZIP_NAME" . \
    -x ".git/*" \
    -x "*.zip" \
    -x "README.md"

echo "✓ AnyKernel3 zip: $ZIP_NAME ($(du -h "$ZIP_NAME" | cut -f1))"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [03] Build Complete ✓"
echo "  Output: $AK3_DIR/$ZIP_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
