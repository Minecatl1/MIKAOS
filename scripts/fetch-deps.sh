#!/bin/bash
set -e

# Download Ubuntu base ISO (4GB)
wget -O base.iso 'https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-desktop-amd64.iso'

# Extract kernel from ISO
7z x -obuild base.iso '[BOOT]/filesystem.squashfs'
unsquashfs -d build/filesystem build/filesystem.squashfs

# Get UEFI components
wget -O build/EFI/efiboot.img https://github.com/linux-surface/linux-surface/releases/download/silverblue-20230313/edk2-ovmf.snap
