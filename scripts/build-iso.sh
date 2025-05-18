#!/bin/bash
set -e

xorriso -as mkisofs \
    -volid "MIKAOS" \
    -rational-rock \
    -joliet \
    -b boot/grub/stage2_eltorito \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -input-charset utf-8 \
    -o output/mikaos.iso \
    build

isohybrid --uefi output/mikaos.iso
