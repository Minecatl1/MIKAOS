#!/bin/bash
set -eo pipefail

# Get GRUB bootloader components
wget -O grub.tar.gz https://ftp.gnu.org/gnu/grub/grub-2.06.tar.gz
tar xzf grub.tar.gz
cp grub-2.06/grub-core/stage2_eltorito build/boot/grub/

# Download verified Ubuntu kernel
wget -O build/boot/vmlinuz https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-image-5.15.0-105-generic_5.15.0-105.115_amd64.deb
dpkg-deb -x linux-image-*.deb build/

# Create proper initrd
mkdir -p build/etc/initramfs-tools
echo "MODULES=dep" > build/etc/initramfs-tools/initramfs.conf
chroot build update-initramfs -c -k all
