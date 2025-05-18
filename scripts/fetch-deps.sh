#!/bin/bash
set -eo pipefail

# Get GRUB stage2_eltorito
wget -O build/boot/grub/stage2_eltorito \
    https://github.com/littleosbook/littleosbook/raw/refs/heads/master/files/stage2_eltorito

# Get custom kernel from ZIP
KERNEL_ZIP="linux_binary_cache-1.0.zip"
KERNEL_DIR="linux_binary_cache-1.0"

echo "Downloading custom kernel..."
wget -O "${KERNEL_ZIP}" https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -o "${KERNEL_ZIP}"

echo "Installing kernel..."
if [ -f "${KERNEL_DIR}/vmlinuz-5.15.0-105" ]; then
    mv "${KERNEL_DIR}/vmlinuz-5.15.0-105" build/boot/vmlinuz
else
    echo "ERROR: Kernel not found in archive!"
    exit 1
fi

echo "Creating initrd..."
mkinitramfs -o build/boot/initrd.img

# Cleanup
rm -rf "${KERNEL_ZIP}" "${KERNEL_DIR}"
