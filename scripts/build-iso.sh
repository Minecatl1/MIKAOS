#!/bin/bash
set -e

genisoimage \
  -V "MIKAOS" \
  -R -J \
  -b boot/grub/stage2_eltorito \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -o output/mikaos.iso \
  build
