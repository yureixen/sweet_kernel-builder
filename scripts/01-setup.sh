#!/bin/bash
# ════════════════════════════════════════════════════════════════
#  01-setup.sh — Environment Setup
#
#  · System dependencies
#  · Neutron Clang (latest, via antman)
#  · Kernel source clone
#  · AnyKernel3 clone
# ════════════════════════════════════════════════════════════════
set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [01] Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── System Dependencies ─────────────────────────────────────────
echo ""
echo "→ Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    git bc bison flex libssl-dev make libc6-dev libncurses5-dev \
    binutils-aarch64-linux-gnu binutils-arm-linux-gnueabi \
    gcc-arm-linux-gnueabi \
    python3 zip unzip curl wget libelf-dev cpio \
    lz4 zstd pahole

echo "✓ Dependencies installed"

# ─── Toolchain: Neutron Clang ────────────────────────────────────
echo ""
echo "→ Setting up Neutron Clang (latest)..."
mkdir -p "$HOME/toolchains/neutron-clang"
cd "$HOME/toolchains/neutron-clang"

curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
chmod +x antman
./antman -S=latest

if [ ! -f "$HOME/toolchains/neutron-clang/bin/clang" ]; then
    echo "✗ Clang not found after install!"
    exit 1
fi

CLANG_VER=$("$HOME/toolchains/neutron-clang/bin/clang" --version | head -1)
echo "✓ Clang ready: $CLANG_VER"

# ─── Kernel Source ───────────────────────────────────────────────
echo ""
echo "→ Cloning kernel source..."
echo "  Repo  : $KERNEL_REPO"
echo "  Branch: $KERNEL_BRANCH"

git clone --depth=1 \
    -b "$KERNEL_BRANCH" \
    "$KERNEL_REPO" \
    "$KERNEL_DIR"

echo "✓ Kernel cloned → $KERNEL_DIR"

# ─── AnyKernel3 ──────────────────────────────────────────────────
echo ""
echo "→ Cloning AnyKernel3..."

if git ls-remote --heads "$AK3_REPO" "$AK3_BRANCH" | grep -q "$AK3_BRANCH"; then
    git clone --depth=1 -b "$AK3_BRANCH" "$AK3_REPO" "$AK3_DIR"
    echo "✓ AnyKernel3 cloned (branch: $AK3_BRANCH)"
else
    echo "⚠ Branch '$AK3_BRANCH' not found, falling back to master..."
    git clone --depth=1 -b master "$AK3_REPO" "$AK3_DIR"
    echo "✓ AnyKernel3 cloned (branch: master)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " [01] Setup Complete ✓"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
