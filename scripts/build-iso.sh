#!/bin/bash
set -e

echo "Building hybrid ISO..."
xorriso -as mkisofs \
  -volid "MikaOS" \
  -eltorito-boot boot/grub/stage2_eltorito \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -o output/mikaos.iso \
  build

echo "ISO created at output/mikaos.iso"
