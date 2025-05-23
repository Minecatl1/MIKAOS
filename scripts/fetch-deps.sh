#!/bin/bash
set -eo pipefail

# List of required tools
REQUIRED_CMDS=(xorriso wget unzip grub-mkstandalone mkinitramfs)

# Check if running as root for package installation
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root to install missing dependencies."
  exit 1
fi

# Install missing tools
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "Installing missing dependency: $cmd"
    apt-get update
    apt-get install -y "$cmd"
  fi
done

# Create initramfs structure
mkdir -p build/etc/initramfs-tools/{conf.d,hooks,scripts}
cat > build/etc/initramfs-tools/initramfs.conf <<EOL
MODULES=most
BUSYBOX=auto
COMPRESS=gzip
DEVICE=eth0
EOL

# Network drivers
cat > build/etc/initramfs-tools/modules <<EOL
e1000
r8169
ath9k
iwlwifi
rt2800usb
usbnet
ax88179_178a
nvme
ahci
i915
EOL

sudo apt-get install linux-image-generic linux-headers-generic
update-initramfs -u

# Get custom kernel
wget -q --show-progress -O linux_binary_cache.zip \
  https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j linux_binary_cache.zip "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Build UEFI GRUB
grub-mkstandalone -O x86_64-efi \
  -o build/EFI/efiboot.img \
  --modules="part_gpt part_msdos fat ext2" \
  --locales="" \
  --themes="" \
  "boot/grub/grub.cfg=config/grub-uefi.cfg"

# Build BIOS GRUB
grub-mkstandalone -O i386-pc \
  -o build/boot/grub/core.img \
  --modules="biosdisk part_msdos iso9660" \
  --locales="" \
  --themes="" \
  "boot/grub/grub.cfg=config/grub-bios.cfg"
cat /usr/lib/grub/i386-pc/cdboot.img build/boot/grub/core.img > build/boot/grub/stage2_eltorito

# Generate initrd
mkinitramfs -d build/etc/initramfs-tools -o build/boot/initrd.img
