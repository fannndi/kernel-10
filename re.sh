#!/bin/bash
set -euo pipefail

DEFCONFIG_NAME="surya_defconfig"
DEFCONFIG_TARGET="arch/arm64/configs/${DEFCONFIG_NAME}"
VENDOR_DEFCONFIG="arch/arm64/configs/vendor/${DEFCONFIG_NAME}"
BACKUP_DEFCONFIG="${VENDOR_DEFCONFIG}.original"
CLANG_VERSION="clang-r450784d"
CLANG_DIR="$HOME/toolchains/$CLANG_VERSION"
TOOLCHAIN_BIN="$CLANG_DIR/bin"
CLANG_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/${CLANG_VERSION}.tar.gz"

echo "🧹 Menghapus symlink jika ada..."
if [ -L "$DEFCONFIG_TARGET" ]; then
    rm "$DEFCONFIG_TARGET"
    echo "✅ Symlink $DEFCONFIG_TARGET dihapus"
elif [ -f "$DEFCONFIG_TARGET" ]; then
    echo "⚠️ $DEFCONFIG_TARGET adalah file biasa, dilewati (tidak dihapus)"
else
    echo "ℹ️ $DEFCONFIG_TARGET tidak ditemukan, lanjut..."
fi

echo "🗃️ Mengecek dan membackup vendor defconfig..."
if [ -f "$VENDOR_DEFCONFIG" ]; then
    echo "📦 Membackup $VENDOR_DEFCONFIG ke $BACKUP_DEFCONFIG"
    mv "$VENDOR_DEFCONFIG" "$BACKUP_DEFCONFIG"
else
    echo "ℹ️ Tidak ada vendor defconfig, skip backup."
fi

echo "📥 Menyalin vendor defconfig ke lokasi aktif (jika ada)..."
if [ -f "$BACKUP_DEFCONFIG" ]; then
    cp "$BACKUP_DEFCONFIG" "$DEFCONFIG_TARGET"
    echo "✅ Disalin dari backup: $BACKUP_DEFCONFIG"
elif [ -f "$VENDOR_DEFCONFIG" ]; then
    cp "$VENDOR_DEFCONFIG" "$DEFCONFIG_TARGET"
    echo "✅ Disalin dari: $VENDOR_DEFCONFIG"
else
    echo "❌ Tidak ditemukan vendor defconfig sebagai dasar build."
    exit 1
fi

echo "🔧 Menyiapkan environment build..."
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export CLANG_TRIPLE=aarch64-linux-gnu-
export PATH="$TOOLCHAIN_BIN:$PATH"

echo "📦 Mengecek toolchain Clang..."
if [ ! -d "$CLANG_DIR" ]; then
    echo "⬇️ Mengunduh toolchain Clang..."
    mkdir -p "$CLANG_DIR"
    cd "$(dirname "$CLANG_DIR")"
    wget -q "$CLANG_URL" -O "${CLANG_VERSION}.tar.gz"
    tar -xf "${CLANG_VERSION}.tar.gz" -C "$CLANG_DIR" --strip-components=1
    rm "${CLANG_VERSION}.tar.gz"
    echo "✅ Toolchain diekstrak ke $CLANG_DIR"
else
    echo "ℹ️ Toolchain sudah ada di $CLANG_DIR, dilewati"
fi

echo "📁 Menyiapkan direktori out/"
mkdir -p out

echo "🛠️ Menyiapkan .config dari $DEFCONFIG_NAME..."
make O=out "$DEFCONFIG_NAME"

# Uncomment jika ingin interaktif
# echo "⚙️ Menjalankan menuconfig..."
# make O=out menuconfig

echo "📄 Menyalin konfigurasi akhir dari out/.config ke $DEFCONFIG_TARGET (FULL)"
cp out/.config "$DEFCONFIG_TARGET"

echo "✅ Sukses regenerate $DEFCONFIG_TARGET dengan konfigurasi lengkap!"
