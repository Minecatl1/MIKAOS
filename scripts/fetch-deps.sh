#!/bin/bash
set -e

# Use Ubuntu Minimal CD (69MB) as base
BASE_URL="http://archive.ubuntu.com/ubuntu/dists/jammy/main/installer-amd64/current/legacy-images/netboot/mini.iso"

echo "Downloading minimal base image..."
wget -O base.iso "$BASE_URL"

echo "Extracting kernel..."
mkdir -p build/boot/grub
7z x -obuild base.iso linux initrd.gz
mv build/linux build/boot/vmlinuz
mv build/initrd.gz build/boot/initrd.img

echo "Preparing GRUB config..."
cat > build/boot/grub/grub.cfg <<EOL
set timeout=10
menuentry "MikaOS" {
    linux /boot/vmlinuz root=/dev/sda1 ro quiet splash
    initrd /boot/initrd.img
}
EOL
