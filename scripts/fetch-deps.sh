#!/bin/bash
set -eo pipefail

# Create UEFI boot image
grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt part_msdos" \
    --install-modules="normal echo linux ls chain" \
    --themes="" \
    --fonts="" \
    --locales="" \
    -o build/EFI/efiboot.img \
    "boot/grub/grub.cfg=config/grub-uefi.cfg"

# BIOS bootloader
grub-mkstandalone -O i386-pc \
    --modules="part_msdos" \
    -o build/boot/grub/stage2_eltorito \
    "boot/grub/grub.cfg=config/grub-bios.cfg"

# Get custom kernel
wget -O linux_binary_cache.zip https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j linux_binary_cache.zip "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Generate initramfs
mkinitramfs -o build/boot/initrd.img
