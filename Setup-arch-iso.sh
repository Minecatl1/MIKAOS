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
          pacman -S --noconfirm archiso git go

      - name: Build the ISO
        run: |
          cp -r /usr/share/archiso/configs/releng/syslinux /__w/${{ github.event.repository.name }}/${{ github.event.repository.name }}/archlive/
          cp -r /usr/share/archiso/configs/releng/efiboot /__w/${{ github.event.repository.name }}/${{ github.event.repository.name }}/archlive/
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
cat > "$BASE_DIR/archlive/airootfs/usr/share/libalpm/hooks/enable-firstboot.hook" << 'EOF'
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = systemd

[Action]
Description = Enabling firstboot systemd service
When = PostTransaction
Exec = /usr/bin/systemctl enable firstboot.service
EOF

cat > "$BASE_DIR/archlive/airootfs/etc/systemd/system/firstboot.service" << 'EOF'
[Unit]
Description=First boot setup (install AUR packages, Flatpaks)
After=network.target lightdm.service
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot-setup.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

cat > "$BASE_DIR/archlive/airootfs/usr/local/bin/firstboot-setup.sh" << 'EOF'
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
EOF

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
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
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
steam
memtest86+
memtest86+-efi
edk2-shell
syslinux

# Audio system - PulseAudio
pulseaudio
pulseaudio-alsa
pulseaudio-bluetooth

# For Pacman
go
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


[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist


[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

echo "✅ Created archlive/airootfs/etc/pacman.conf"

cat > "$BASE_DIR/archlive/pacman.conf" << 'EOF'
[options]
HoldPkg     = pacman glibc
Architecture = auto
Color
CheckSpace
ParallelDownloads = 5
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional


[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist


[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

echo "Made pacman.conf in archlive root"

# Make the customization script executable
chmod +x "$BASE_DIR/archlive/airootfs/usr/local/bin/firstboot-setup.sh"

echo "✅ Created and made executable: archlive/airootfs/usr/local/bin/firstboot-setup.sh"

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
