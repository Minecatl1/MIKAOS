#!/bin/bash
set -e

# Only run once
FLAG_FILE="/var/lib/firstboot-done"
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

echo "Running first‑boot setup..."

# Create temporary build user for AUR packages
useradd -m -s /bin/bash builduser
echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install yay
sudo -u builduser bash -c 'cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm'
rm -rf /tmp/yay

# Install bauh with yay (as root, since yay is now installed)
yay -S --noconfirm bauh

# Cleanup
userdel -r builduser
sed -i '/builduser ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers
yay -Sc --noconfirm

# Configure Flatpak and install apps
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub io.itch.itch com.opera.opera-gx org.vinegarhq.Sober dev.vencord.Vesktop

# Set up desktop launchers for the live user (arch)
DESKTOP="/home/arch/Desktop"
mkdir -p "$DESKTOP/Game Launchers"
ln -sf /usr/share/applications/steam.desktop "$DESKTOP/Game Launchers/steam.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/io.itch.itch.desktop "$DESKTOP/Game Launchers/io.itch.itch.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/com.opera.opera-gx.desktop "$DESKTOP/opera-gx.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/org.vinegarhq.Sober.desktop "$DESKTOP/sober.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/dev.vencord.Vesktop.desktop "$DESKTOP/vesktop.desktop"
chown -R arch:arch "$DESKTOP"

# Mark completion
touch "$FLAG_FILE"
echo "First‑boot setup complete."
