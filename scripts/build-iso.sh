#!/bin/bash
set -e

xorriso -as mkisofs \
  -volid "MikaOS" \
  -b boot/grub/stage2_eltorito \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot \
  -o output/mikaos.iso \
  build/filesystem

isohybrid --uefi output/mikaos.iso
