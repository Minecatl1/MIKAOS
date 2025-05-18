#!/bin/bash
set -eo pipefail

# Create initramfs directory structure first
mkdir -p build/etc/initramfs-tools/conf.d
mkdir -p build/boot/grub

# Then create config files
cat > build/etc/initramfs-tools/conf.d/root <<EOL
MODULES=most
BOOT=local
DEVICE=eth0
ROOT=UUID=00000000-0000-0000-0000-000000000000
ROOTFSTYPE=ext4
EOL

# Rest of the script remains the same
echo "virtio_pci virtio_blk virtio_net" >> build/etc/initramfs-tools/modules

# Get custom kernel
wget -O linux_binary_cache.zip https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j linux_binary_cache.zip "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Generate initrd
mkinitramfs -d build/etc/initramfs-tools -o build/boot/initrd.img
