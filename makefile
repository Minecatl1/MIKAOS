# MikaOS Makefile
# Build Ubuntu-based GNOME OS with Flatpak, Snap, apps, installer, and persistence

IMAGE_NAME := mikaos
CHROOT := chroot
ISO_NAME := $(IMAGE_NAME).iso
IMG_NAME := $(IMAGE_NAME).img
KERNEL_PKG := linux-generic

EXTRA_PKGS := ubuntu-desktop gdm3 $(KERNEL_PKG) network-manager \
              flatpak gnome-software gnome-software-plugin-flatpak gnome-software-plugin-snap \
              firefox gedit gvfs-backends \
              gnome-calendar gnome-maps gnome-weather gnome-clocks gnome-logs gnome-contacts \
              ca-certificates sudo openssh-client pulseaudio alsa-utils gnome-terminal \
              gnome-control-center gnome-system-monitor \
              apt apt-utils software-properties-common bash-completion less nano vim \
              whiptail dialog casper rsync grub-pc parted

all: iso img

# Step 1: Create folders
dirs:
	@echo "=== Creating required folders ==="
	mkdir -p $(CHROOT)/proc $(CHROOT)/sys $(CHROOT)/dev $(CHROOT)/tmp
	mkdir -p $(CHROOT)/usr/local/bin
	mkdir -p $(CHROOT)/usr/share/applications
	mkdir -p $(CHROOT)/etc/profile.d
	mkdir -p build iso_root

# Step 2: Build base system
prepare: dirs
	@echo "=== Preparing base system ==="
	sudo debootstrap --arch=amd64 focal $(CHROOT) http://archive.ubuntu.com/ubuntu/

# Step 3: Populate system with packages, scripts, and configs
populate: prepare
	@echo "=== Installing packages into chroot ==="
	sudo chroot $(CHROOT) apt-get update
	sudo chroot $(CHROOT) apt-get install -y $(EXTRA_PKGS)

	@echo "=== Enable GNOME and NetworkManager ==="
	sudo chroot $(CHROOT) systemctl enable gdm3
	sudo chroot $(CHROOT) systemctl enable NetworkManager

	@echo "=== Enable Flatpak + Flathub ==="
	sudo chroot $(CHROOT) bash -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

	@echo "=== Install default Flatpak apps ==="
	sudo chroot $(CHROOT) bash -c \
	  "flatpak install -y flathub com.spotify.Client org.videolan.VLC org.gimp.GIMP com.valvesoftware.Steam"

	@echo "=== Ensure Flatpak apps appear in GNOME menu ==="
	echo 'XDG_DATA_DIRS="/usr/share:/usr/local/share:/var/lib/flatpak/exports/share:$HOME/.local/share"' \
	  | sudo tee -a $(CHROOT)/etc/environment

	@echo "=== Create CLI/GNOME mode chooser script ==="
	sudo chroot $(CHROOT) bash -c 'cat > /usr/local/bin/mikaos-mode-chooser << "EOF"
#!/bin/bash
CHOICE=$(whiptail --title "MikaOS Mode Selector" --menu "Choose your mode:" 15 50 2 \
"1" "GNOME Desktop" \
"2" "Command Line" 3>&1 1>&2 2>&3)

case $CHOICE in
  1) systemctl set-default graphical.target && systemctl isolate graphical.target ;;
  2) systemctl set-default multi-user.target && systemctl isolate multi-user.target ;;
esac
EOF'
	sudo chroot $(CHROOT) chmod +x /usr/local/bin/mikaos-mode-chooser

	@echo "=== Create .desktop entry for mode chooser ==="
	sudo chroot $(CHROOT) bash -c 'cat > /usr/share/applications/mikaos-mode-chooser.desktop << "EOF"
[Desktop Entry]
Name=MikaOS Mode Chooser
Comment=Choose between GNOME Desktop or Command Line mode
Exec=/usr/local/bin/mikaos-mode-chooser
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF'
	sudo chroot $(CHROOT) chmod 644 /usr/share/applications/mikaos-mode-chooser.desktop
	sudo chroot $(CHROOT) update-desktop-database /usr/share/applications

	@echo "=== Create MikaOS installer script ==="
	sudo chroot $(CHROOT) bash -c 'cat > /usr/local/bin/mikaos-installer << "EOF"
#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

TARGET_DISK=$(whiptail --inputbox "Enter target disk (e.g., /dev/sda):" 10 60 /dev/sda 3>&1 1>&2 2>&3)
if [ -z "$TARGET_DISK" ]; then
  echo "Installation cancelled."
  exit 1
fi

echo "=== Partitioning $TARGET_DISK ==="
parted --script "$TARGET_DISK" mklabel gpt mkpart primary ext4 1MiB 100%

echo "=== Formatting partition ==="
mkfs.ext4 "${TARGET_DISK}1"

echo "=== Mounting target ==="
mount "${TARGET_DISK}1" /mnt

echo "=== Copying system files ==="
rsync -aAX /* /mnt --exclude=/mnt --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp

echo "=== Installing GRUB ==="
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
chroot /mnt grub-install "$TARGET_DISK"
chroot /mnt update-grub

echo "=== Enable persistence ==="
echo "PERSISTENCE=1" > /mnt/etc/mikaos.conf

umount -R /mnt

whiptail --msgbox "Installation complete! You can now reboot into your new MikaOS system." 10 60
EOF'
	sudo chroot $(CHROOT) chmod +x /usr/local/bin/mikaos-installer

	@echo "=== Add installer to GNOME menu ==="
	sudo chroot $(CHROOT) bash -c 'cat > /usr/share/applications/mikaos-installer.desktop << "EOF"
[Desktop Entry]
Name=Install MikaOS to Disk
Comment=Install MikaOS from live session to your hard drive
Exec=pkexec /usr/local/bin/mikaos-installer
Icon=drive-harddisk
Terminal=false
Type=Application
Categories=System;
EOF'
	sudo chroot $(CHROOT) chmod 644 /usr/share/applications/mikaos-installer.desktop
	sudo chroot $(CHROOT) update-desktop-database /usr/share/applications

	@echo "=== Persistence check script ==="
	sudo chroot $(CHROOT) bash -c 'cat > /etc/profile.d/mikaos-persistence.sh << "EOF"
if [ -f /etc/mikaos.conf ]; then
  source /etc/mikaos.conf
  if [ "\$$PERSISTENCE" = "1" ]; then
    echo "MikaOS Persistence Enabled"
  fi
fi
EOF'
	sudo chroot $(CHROOT) chmod +x /etc/profile.d/mikaos-persistence.sh

	@echo "=== Set default target to GNOME Desktop ==="
	sudo chroot $(CHROOT) systemctl set-default graphical.target

	@echo "=== Cleaning up chroot ==="
	sudo chroot $(CHROOT) apt-get clean
	sudo rm -rf $(CHROOT)/var/lib/apt/lists/*

# Step 4: Build ISO
iso: populate
	@echo "=== Building ISO ==="
	sudo mkisofs -D -r -V "MikaOS" -cache-inodes -J -l \
	  -b isolinux/isolinux.bin -c isolinux/boot.cat \
	  -no-emul-boot -boot-load-size 4 -boot-info-table \
	  -o $(ISO_NAME) $(CHROOT)

# Step 5: Build IMG
img: populate
	@echo "=== Building IMG ==="
	dd if=/dev/zero of=$(IMG_NAME) bs=1M count=2048
	mkfs.ext4 $(IMG_NAME)
	sudo mount -o loop $(IMG_NAME) /mnt
	sudo cp -a $(CHROOT)/* /mnt/
	sudo umount /mnt

# Step 6: Clean build files
clean:
	sudo rm -rf $(CHROOT) $(ISO_NAME) $(IMG_NAME) build iso_root
