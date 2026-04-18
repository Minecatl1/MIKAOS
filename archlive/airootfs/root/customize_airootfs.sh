#!/bin/bash

# Enable essential services
systemctl enable NetworkManager.service
systemctl enable lightdm.service

# --- Audio Setup ---
systemctl --global enable pulseaudio

# --- Flatpak Setup ---
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# --- Install Itch launcher via Flatpak ---
flatpak install -y flathub io.itch.itch
flatpak install -y flathub com.opera.opera-gx

# --- Create Game Launchers folder on desktop ---
DESKTOP_DIR="/home/arch/Desktop/Game Launchers"
mkdir -p "$DESKTOP_DIR"

# Symlink Steam and Itch desktop files
ln -sf /usr/share/applications/steam.desktop "$DESKTOP_DIR/steam.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/io.itch.itch.desktop "$DESKTOP_DIR/io.itch.itch.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/com.opera.opera-gx.desktop "$DESKTOP_DIR/com.opera.opera-gx.desktop"
# Set correct ownership
chown -R arch:arch "/home/arch/Desktop"

# Optional: Inform user about AUR helper (yay) being available
echo "yay AUR helper is installed and ready to use." > /etc/motd
