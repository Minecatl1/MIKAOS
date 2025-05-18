#!/bin/bash
set -e

sudo mount --bind /dev build/filesystem/dev
sudo mount -t proc proc build/filesystem/proc

sudo chroot build/filesystem /bin/bash <<'EOL'
apt update
apt install -y flatpak gnome-software
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
update-initramfs -u
EOL

sudo umount build/filesystem/dev
sudo umount build/filesystem/proc
