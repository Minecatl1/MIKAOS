#!/bin/bash
set -eo pipefail

# Get BIOS bootloader
wget -O build/boot/grub/stage2_eltorito \
    https://github.com/littleosbook/littleosbook/raw/master/files/stage2_eltorito

# Create UEFI boot image
mkdir -p build/EFI
grub-mkstandalone -O x86_64-efi \
    -o build/EFI/efiboot.img \
    --modules="part_gpt part_msdos" \
    --locales="" \
    --themes="" \
    /boot/grub/grub.cfg=config/grub-uefi.cfg

# Get custom kernel
KERNEL_ZIP="linux_binary_cache-1.0.zip"
wget -O "${KERNEL_ZIP}" https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j "${KERNEL_ZIP}" "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Create initrd
mkinitramfs -o build/boot/initrd.img
