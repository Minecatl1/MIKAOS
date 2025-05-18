#!/bin/bash
set -eo pipefail

# Create initramfs config with device discovery
mkdir -p build/etc/initramfs-tools
cat > build/etc/initramfs-tools/conf.d/root <<EOL
MODULES=most
BOOT=local
DEVICE=eth0
ROOT=UUID=00000000-0000-0000-0000-000000000000
ROOTFSTYPE=ext4
EOL

# Force include virtio drivers for cloud environments
echo "virtio_pci virtio_blk virtio_net" >> build/etc/initramfs-tools/modules

# Generate initrd with dummy root
mkinitramfs -d build/etc/initramfs-tools \
    -k build/boot/vmlinuz \
    -o build/boot/initrd.img \
    --force
