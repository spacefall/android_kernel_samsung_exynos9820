#!/bin/bash
# Loosely based on https://github.com/LeDrew2017/FreeRunnerKernel/blob/7a99c2fe668a064942d124d805e79034674757a6/build.sh

DEVICE="beyondx"
OUT="out"
CONFIGS=(
    "exynos9820-beyondx_defconfig"
    "kernelsu.config"
    "droidspaces.config"
    "droidspaces-additional.config"
    "docker.config"
    "additional.config"
    "lto.config"
)
ADDITIONAL_BUILD_FLAGS=(
    "LLVM_IAS=1"
)

export PATH="/usr/lib/ccache:$HOME/toolchain/bin:$PATH"
export ARCH=arm64

perform_clean() {
    echo "🧹 Cleaning up..."
    make O="$OUT" LLVM=1 mrproper
    echo "✅ Clean complete."
}

build_kernel() {
    echo "🔧 Starting build for: $DEVICE"
    make O="$OUT" LLVM=1 "${CONFIGS[@]}"

    local build_start
    build_start=$(date +%s)
    make O="$OUT" LLVM=1 -j"$(nproc)" "${ADDITIONAL_BUILD_FLAGS[@]}"
    local build_end
    build_end=$(date +%s)
    local duration=$((build_end - build_start))

    if [ ! -f "$OUT/arch/arm64/boot/Image" ]; then
        echo "❌ Build failed after $(printf "%02d:%02d" $((duration / 60)) $((duration % 60)))"
        exit 1
    fi
    echo "✅ Build completed in $(printf "%02d:%02d" $((duration / 60)) $((duration % 60)))"
}

boot_repack() {
    cd pack
    rm boot.img og-boot.img -f
    zstd -d og-boot.img.zst
    mkdir boot
    cd boot
    ../magiskboot unpack ../og-boot.img
    cp ../../out/arch/arm64/boot/Image kernel
    ../magiskboot repack ../og-boot.img ../boot.img
    cd ..
    rm boot/ -rf
    echo "✅ Done repacking boot image."
    cd ..
}

if [[ "$1" == "--clean" ]]; then
    perform_clean
    exit 0
fi

if [[ "$1" == "--cfg" ]]; then
    make O="$OUT" LLVM=1 "${CONFIGS[@]}"
    exit 0
fi

if [[ "$1" == "--menu" ]]; then
    make O="$OUT" LLVM=1 menuconfig
    exit 0
fi

if [[ "$1" == "--ncfg" ]]; then
    make O="$OUT" LLVM=1 nconfig
    exit 0
fi

if [[ "$1" == "--repack" ]]; then
    boot_repack
    exit 0
fi

if [[ "$1" == "--boot" ]]; then
    boot_repack
    exit 0
fi

if [[ "$1" != "--inc" ]]; then
   perform_clean
fi

build_kernel
boot_repack
echo "🎉 Build for $DEVICE is complete."