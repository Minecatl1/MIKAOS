#!/bin/bash
# setup-iso-project.sh - Generate all files and folders for the custom Arch ISO project

set -e  # Exit on any error

echo "🚀 Setting up Custom Arch ISO project structure..."

# Define the base directory (current directory by default)
BASE_DIR="$(pwd)"

# Create directory structure
mkdir -p "$BASE_DIR/.github/workflows"
mkdir -p "$BASE_DIR/archlive/airootfs/etc"
mkdir -p "$BASE_DIR/archlive/airootfs/root"

echo "📁 Created directory structure."

# ---------------------------------------------------------------------
# 1. GitHub Actions Workflow
# ---------------------------------------------------------------------
cat > "$BASE_DIR/.github/workflows/build-iso.yml" << 'EOF'
name: Build Custom Arch ISO

on:
  workflow_dispatch:
    inputs:
      version_tag:
        description: 'Tag for the release (e.g., v1.0.0)'
        required: true
        default: 'latest'
  push:
    branches:
      - main
    paths:
      - 'archlive/**'
      - '.github/workflows/build-iso.yml'

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: archlinux:latest
      options: --privileged
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install build dependencies
        run: |
          pacman -Syu --noconfirm
          pacman -S --noconfirm archiso git

      - name: Build yay package for custom repo
        run: |
          # Build yay from AUR
          pacman -S --noconfirm --needed base-devel
          useradd -m builder
          echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
          su - builder -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm"
          # Create custom repo directory and copy the built package
          mkdir -p /__w/${{ github.event.repository.name }}/${{ github.event.repository.name }}/archlive/custom_repo
          cp /tmp/yay/*.pkg.tar.zst /__w/${{ github.event.repository.name }}/${{ github.event.repository.name }}/archlive/custom_repo/
          cd /__w/${{ github.event.repository.name }}/${{ github.event.repository.name }}/archlive/custom_repo
          repo-add custom_repo.db.tar.gz *.pkg.tar.zst
        shell: bash

      - name: Build the ISO
        run: |
          mkdir -p /tmp/archiso-tmp
          mkarchiso -v -w /tmp/archiso-tmp -o . /__w/${{ github.event.repository.name }}/${{ github.event.repository.name }}/archlive
        shell: bash

      - name: Upload ISO artifact
        uses: actions/upload-artifact@v4
        with:
          name: custom-arch-iso
          path: ./*.iso

  release:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    steps:
      - name: Download ISO artifact
        uses: actions/download-artifact@v4
        with:
          name: custom-arch-iso

      - name: Create Release and Upload ISO
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.event.inputs.version_tag }}
          name: Custom Arch Linux ${{ github.event.inputs.version_tag }}
          body: |
            This release contains a custom Arch Linux ISO built on ${{ github.event.repository.updated_at }}.
            
            **Features:**
            - Lightweight desktop (Xfce)
            - yay AUR helper preinstalled
            - Flatpak with Flathub remote
            - Bauh GUI package manager
            - Steam and Itch launchers in a "Game Launchers" desktop folder
            
            To use: Write the ISO to a USB drive using `dd` or balenaEtcher.
          files: |
            *.iso
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

echo "✅ Created .github/workflows/build-iso.yml"

# ---------------------------------------------------------------------
# 2. Packages list
# ---------------------------------------------------------------------
cat > "$BASE_DIR/archlive/profiledef.sh" << 'EOF'
#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="gaming-arch-linux"
iso_label="GAMING_ARCH_$(date +%Y%m)"
iso_publisher="Custom built Arch Linux <https://github.com>"
iso_application="Gaming Arch Linux Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
)
EOF
cat > "$BASE_DIR/archlive/packages.x86_64" << 'EOF'
# Base system
base
base-devel
linux
linux-firmware
nano
sudo
fish
flatpak
git
networkmanager

# Desktop Environment - Xfce (lightweight and customizable)
xfce4
xfce4-goodies
lightdm
lightdm-gtk-greeter

# Additional tools
bauh
steam

# Audio system - PulseAudio
pulseaudio
pulseaudio-alsa
pulseaudio-bluetooth
EOF

echo "✅ Created archlive/packages.x86_64"

# ---------------------------------------------------------------------
# 3. pacman.conf (with multilib and custom repo)
# ---------------------------------------------------------------------
cat > "$BASE_DIR/archlive/airootfs/etc/pacman.conf" << 'EOF'
[options]
HoldPkg     = pacman glibc
Architecture = auto
Color
CheckSpace
ParallelDownloads = 5
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[custom_repo]
SigLevel = Optional TrustAll
Server = file:///custom_repo

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

echo "✅ Created archlive/airootfs/etc/pacman.conf"

# ---------------------------------------------------------------------
# 4. Post-installation customization script
# ---------------------------------------------------------------------
cat > "$BASE_DIR/archlive/airootfs/root/customize_airootfs.sh" << 'EOF'
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
EOF

# Make the customization script executable
chmod +x "$BASE_DIR/archlive/airootfs/root/customize_airootfs.sh"

echo "✅ Created and made executable: archlive/airootfs/root/customize_airootfs.sh"

# ---------------------------------------------------------------------
# 5. (Optional) Initialize git repository and commit
# ---------------------------------------------------------------------
if [ ! -d "$BASE_DIR/.git" ]; then
    echo "📌 Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: Custom Arch ISO project"
    echo "✅ Git repository initialized and files committed."
else
    echo "ℹ️ Git repository already exists. Skipping initialization."
fi

echo ""
echo "🎉 All done! Your custom Arch ISO project is ready."
echo "📂 Project location: $BASE_DIR"
echo ""
echo "Next steps:"
echo "1. Push this repository to GitHub:"
echo "   git remote add origin https://github.com/yourusername/your-repo.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "2. Go to the Actions tab on GitHub and manually trigger the workflow."
echo "3. After the workflow completes, the ISO will be attached to a new Release."
