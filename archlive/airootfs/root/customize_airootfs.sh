#!/bin/bash

# Enable essential services
systemctl enable NetworkManager.service
systemctl enable lightdm.service

# --- Install yay AUR helper ---
sudo -u arch bash -c 'cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm'
rm -rf /tmp/yay

# --- Install bauh (GUI Package Manager) using yay ---
echo "Installing bauh from AUR..."
sudo -u arch bash -c 'yay -S --noconfirm bauh'
# Clean up yay cache to save space
sudo -u arch bash -c 'yay -Sc --noconfirm'

# --- Audio Setup ---
systemctl --global enable pulseaudio

# --- Flatpak Setup ---
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# --- Install Itch launcher via Flatpak ---
flatpak install -y flathub io.itch.itch
flatpak install -y flathub com.opera.opera-gx
flatpak install -y flathub org.vinegarhq.Sober
flatpak install -y flathub dev.vencord.Vesktop

# --- Create Game Launchers folder on desktop ---
DESKTOP_DIR="/home/arch/Desktop"
mkdir -p "$DESKTOP_DIR"

# Symlink Steam and Itch desktop files
ln -sf /usr/share/applications/steam.desktop "$DESKTOP_DIR/Game Launchers/steam.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/io.itch.itch.desktop "$DESKTOP_DIR/Game Launchers/io.itch.itch.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/com.opera.opera-gx.desktop "$DESKTOP_DIR/com.opera.opera-gx.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/org.vinegarhq.Sober.desktop "$DESKTOP_DIR/org.vinegarhq.Sober.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/dev.vencord.Vesktop.desktop "$DESKTOP_DIR/dev.vencord.Vesktop.desktop"

# Set correct ownership
chown -R arch:arch "/home/arch/Desktop"

# Optional: Inform user about AUR helper (yay) being available
echo "yay AUR helper is installed and ready to use." > /etc/motd
