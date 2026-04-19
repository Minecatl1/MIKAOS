#!/bin/bash

set -e  # Stop on any error

echo "==> Starting post-install customization..."

# --- Enable essential services ---
systemctl enable NetworkManager.service
systemctl enable lightdm.service

# --- Audio Setup (PulseAudio) ---
systemctl --global enable pulseaudio


# Copy memtest86+ binary to ISO boot directory
mkdir -p /arch/boot/memtest86+
cp /usr/share/memtest86+/memtest.bin /arch/boot/memtest86+/memtest.bin 2>/dev/null || echo "Memtest86+ not found"

# --- Create a temporary build user for AUR packages ---
echo "==> Creating temporary build user..."
useradd -m -s /bin/bash builduser
echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


# --- Clean up temporary user and cache ---
echo "==> Cleaning up temporary user and package caches..."
userdel -r builduser
sed -i '/builduser ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers

# --- Flatpak Setup ---
echo "==> Configuring Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Flatpak applications (suppress non‑critical bwrap warnings)
flatpak install --system -y flathub io.itch.itch 2>/dev/null || true
flatpak install --system -y flathub com.opera.opera-gx 2>/dev/null || true
flatpak install --system -y flathub org.vinegarhq.Sober 2>/dev/null || true
flatpak install --system -y flathub dev.vencord.Vesktop 2>/dev/null || true

# --- Create desktop launchers in /etc/skel (will appear for live user) ---
echo "==> Setting up desktop launchers..."
SKEL_DESKTOP="/etc/skel/Desktop"
GAME_LAUNCHERS_DIR="$SKEL_DESKTOP/Game Launchers"

mkdir -p "$GAME_LAUNCHERS_DIR"

# Steam and Itch in the Game Launchers folder
ln -sf /usr/share/applications/steam.desktop "$GAME_LAUNCHERS_DIR/steam.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/io.itch.itch.desktop "$GAME_LAUNCHERS_DIR/io.itch.itch.desktop"

# Other apps directly on the desktop
ln -sf /var/lib/flatpak/exports/share/applications/com.opera.opera-gx.desktop "$SKEL_DESKTOP/opera-gx.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/org.vinegarhq.Sober.desktop "$SKEL_DESKTOP/sober.desktop"
ln -sf /var/lib/flatpak/exports/share/applications/dev.vencord.Vesktop.desktop "$SKEL_DESKTOP/vesktop.desktop"

# --- Optional message for users ---
echo "yay AUR helper is installed and ready to use." > /etc/motd

echo "==> Customization complete!"
