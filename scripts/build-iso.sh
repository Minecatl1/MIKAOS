#!/bin/bash
set -e

# Generate module dependencies for custom kernel
depmod -b build $(basename build/boot/vmlinuz | sed 's/vmlinuz-//')

xorriso -as mkisofs \
    -volid "MIKAOS" \
    -rational-rock \
    -joliet \
    -b boot/grub/stage2_eltorito \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o output/mikaos.iso \
    build
