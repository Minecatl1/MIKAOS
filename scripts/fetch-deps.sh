#!/bin/bash
set -eo pipefail

# Use reliable Ubuntu minimal ISO mirror
BASE_URL="https://mirrors.edge.kernel.org/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso"

echo "Downloading base image..."
if ! wget -O base.iso "$BASE_URL"; then
  echo "Failed to download base ISO"
  exit 1
fi

echo "Extracting kernel..."
mkdir -p build/boot/grub
if ! 7z x -obuild base.iso linux initrd.gz; then
  echo "ISO extraction failed - trying alternative method"
  sudo apt-get install -y fuseiso
  mkdir -p iso_mount
  fuseiso base.iso iso_mount
  cp iso_mount/linux iso_mount/initrd.gz build/
  fusermount -u iso_mount
fi

echo "Organizing boot files..."
mv -v build/linux build/boot/vmlinuz || true
mv -v build/initrd.gz build/boot/initrd.img || true

echo "Creating GRUB config..."
cat > build/boot/grub/grub.cfg <<EOL
set timeout=5
menuentry "MikaOS" {
    linux /boot/vmlinuz quiet splash
    initrd /boot/initrd.img
}
EOL
