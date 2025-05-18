#!/bin/bash
set -e

# Use partial ISO download to save space
wget --no-check-certificate \
    --header="Range: bytes=0-100000000" \
    -O partial.iso \
    https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-desktop-amd64.iso

# Extract just the essential boot files
7z x -obuild partial.iso '[BOOT]'
