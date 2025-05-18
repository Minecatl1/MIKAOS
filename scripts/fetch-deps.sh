#!/bin/bash
set -eo pipefail

# Create initramfs directory structure
mkdir -p build/etc/initramfs-tools/{conf.d,hooks,scripts}
cp -r /etc/initramfs-tools/* build/etc/initramfs-tools/ || true

# Generate basic initramfs config
cat > build/etc/initramfs-tools/conf.d/default <<EOL
MODULES=dep
COMPRESS=gzip
EOL

# Create UEFI boot image
grub-mkstandalone -O x86_64-efi \
    -o build/EFI/efiboot.img \
    --modules="part_gpt part_msdos" \
    --locales="" \
    --themes="" \
    /boot/grub/grub.cfg=config/grub-uefi.cfg

# Get custom kernel
wget -O linux_binary_cache.zip https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j linux_binary_cache.zip "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Create initrd using host config if missing
if [ ! -f build/etc/initramfs-tools/initramfs.conf ]; then
    cp /etc/initramfs-tools/initramfs.conf build/etc/initramfs-tools/
fi

mkinitramfs -d build/etc/initramfs-tools -o build/boot/initrd.img
