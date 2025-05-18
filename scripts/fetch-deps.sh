#!/bin/bash
set -e

# Get GRUB stage2
wget -O build/boot/grub/stage2_eltorito \
    https://github.com/littleosbook/littleosbook/raw/refs/heads/master/files/stage2_eltorito

# Get Linux kernel
wget -O build/boot/vmlinuz \
    https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-image-5.15.0-105-generic_5.15.0-105.115_amd64.deb

# Extract kernel
dpkg-deb -x build/boot/vmlinuz build/
find build/usr/lib/modules -name "vmlinuz" -exec mv {} build/boot/vmlinuz \;

# Create initrd
mkinitramfs -d build/etc/initramfs-tools -o build/boot/initrd.img
