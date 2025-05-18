#!/bin/bash
set -eo pipefail

# Create optimized UEFI boot image
grub-mkimage -O x86_64-efi \
    -p /boot/grub \
    -c config/grub-uefi.cfg \
    -o build/EFI/efiboot.img \
    part_gpt part_msdos fat ext2 iso9660 linux normal \
    search_fs_uuid search_fs_file ls chain echo configfile

# Create optimized BIOS bootloader
grub-mkimage -O i386-pc \
    -p /boot/grub \
    -c config/grub-bios.cfg \
    -o build/boot/grub/core.img \
    biosdisk part_msdos iso9660 linux normal \
    search_fs_uuid search_fs_file ls chain echo configfile

# Combine BIOS components
cat /usr/lib/grub/i386-pc/cdboot.img build/boot/grub/core.img > build/boot/grub/stage2_eltorito

# Get custom kernel
wget -O linux_binary_cache.zip https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j linux_binary_cache.zip "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Create minimal initrd
mkinitramfs -d build/etc/initramfs-tools -o build/boot/initrd.img
