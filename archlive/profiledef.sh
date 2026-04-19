#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="gaming-arch-linux"
iso_label="GAMING_ARCH_$(date +%Y%m)"
iso_publisher="Custom built Arch Linux <https://github.com>"
iso_application="Gaming Arch Linux Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'bios.grub' 'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
