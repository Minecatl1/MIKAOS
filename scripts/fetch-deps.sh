#!/bin/bash
set -eo pipefail

# List of required tools
REQUIRED_CMDS=(genisoimage wget unzip grub-mkstandalone mkinitramfs pkexec policykit-1 xterm gnome-terminal konsole zenity flatpak libnotify4)

# Check if running as root for package installation
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root to install missing dependencies."
  exit 1
fi

# Install missing tools
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "Installing missing dependency: $cmd"
    apt-get update
    apt-get install -y "$cmd"
  fi
done

# Create initramfs structure
mkdir -p build/etc/initramfs-tools/{conf.d,hooks,scripts}
cat > build/etc/initramfs-tools/initramfs.conf <<EOL
MODULES=most
BUSYBOX=auto
COMPRESS=gzip
DEVICE=eth0
EOL

# Network drivers
cat > build/etc/initramfs-tools/modules <<EOL
e1000
r8169
ath9k
iwlwifi
rt2800usb
usbnet
ax88179_178a
nvme
ahci
i915
EOL

sudo apt-get install linux-image-generic linux-headers-generic
update-initramfs -u

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Get custom kernel
wget -q --show-progress -O linux_binary_cache.zip \
  https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
unzip -j linux_binary_cache.zip "linux_binary_cache-1.0/vmlinuz-5.15.0-105" -d build/boot/
mv build/boot/vmlinuz-5.15.0-105 build/boot/vmlinuz

# Download Google Chrome .deb to config/packages if not already present
CHROME_DEB="config/packages/google-chrome-stable_current_amd64.deb"
if [ ! -f "$CHROME_DEB" ]; then
  wget -O "$CHROME_DEB" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
fi

# Get Steam
# Download Steam .deb to config/packages if not already present
STEAM_DEB="config/packages/steam.deb"
if [ ! -f "$STEAM_DEB" ]; then
  wget -O "$STEAM_DEB" "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb"
fi

HEROIC_DEB="config/packages/heroic.deb"
if [ ! -f "$HEROIC_DEB" ]; then
  wget -O "$HEROIC_DEB" "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.17.0/Heroic-2.17.0-linux-amd64.deb"
fi

for pkg in config/packages/*.deb; do
    [ -e "$pkg" ] || continue  # Skip if no .deb files exist
    dpkg -i "$pkg"
done

# Generate initrd
mkinitramfs -d build/etc/initramfs-tools -o build/boot/initrd.img
