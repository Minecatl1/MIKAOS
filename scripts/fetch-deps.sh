#!/bin/bash
set -eo pipefail

# Get GRUB stage2_eltorito from littleosbook
echo "Downloading GRUB stage2_eltorito..."
wget -O build/boot/grub/stage2_eltorito \
    https://github.com/littleosbook/littleosbook/raw/refs/heads/master/files/stage2_eltorito

# Verify and set permissions
chmod +x build/boot/grub/stage2_eltorito

# Download Ubuntu kernel
echo "Fetching Linux kernel..."
wget -O build/boot/vmlinuz \
    https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-image-5.15.0-105-generic_5.15.0-105.115_amd64.deb

# Extract kernel package
dpkg-deb -x build/boot/vmlinuz build/
mv build/boot/vmlinuz-* build/boot/vmlinuz

# Create initrd
mkinitramfs -o build/boot/initrd.img
