# Makefile for building Ubuntu MikaOS ISO with dynamic app fetching

# Output and file paths
ISO_NAME := output/mikaos.iso
ROOT_FS := build/filesystem
FILES_DIR := files
OUTPUT_DIR := output
GRUB_CFG := build/grub_config/grub.cfg
CHROMEOS_FLEX_DIR := chromeos-flex
Bui := build/filesystem/boot/grub/
CONFIG_FILE := iso_config.txt

# Tools
MKISOFS := genisoimage
MKDIR := mkdir -p
CP := cp
RM := rm -rf
CHROOT := sudo chroot $(ROOT_FS)

# Default target
all: buildfl get-deps fetch-files prepare_dirs customize-rootfs build_iso

# Step 2: Create necessary folders
buildfl:
	@echo "Creating required folders..."
	$(MKDIR) $(FILES_DIR)
	$(MKDIR) $(ROOT_FS)/boot/grub
	$(MKDIR) $(ROOT_FS)/usr/local/bin
	$(MKDIR) $(OUTPUT_DIR)
	@echo "All folders created successfully!"

# Step 3: Install dependencies from requirements.txt
get-deps:
	sudo apt update
	@echo "Installing dependencies from requirements.txt..."
	@xargs -a requirements.txt sudo apt install -y
	pip install --upgrade pip
	pip install flask
	@echo "Configuring Bluetooth and Wi-Fi..."

# Step 4: Fetch required files dynamically based on iso_config.txt
fetch-files:
	@echo "Fetching required files based on iso_config.txt..."
	@cat $(CONFIG_FILE) | grep "Apps:" | cut -d':' -f2 | tr ',' '\n' | while read app; do \
		echo "Installing $$app..."; \
		sudo apt install -y $$app || echo "Failed to install $$app. Continuing."; \
	done
	@echo "Downloading kernel archive..."
	wget -O $(FILES_DIR)/kernel_cache.zip https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
	@echo "Unzipping kernel archive..."
	unzip -o $(FILES_DIR)/kernel_cache.zip -d $(FILES_DIR)
	@echo "Moving vmlinuz-5.15.0-105 to the correct location..."
	$(MKDIR) $(ROOT_FS)/boot
	mv $(FILES_DIR)/linux_binary_cache-1.0/vmlinuz-5.15.0-105 $(ROOT_FS)/boot/vmlinuz-linux
	@echo "Downloading stage2_eltorito..."
	wget -O $(Bui)/stage2_eltorito https://github.com/littleosbook/littleosbook/raw/refs/heads/master/files/stage2_eltorito

# Step 5: Prepare filesystem and directories
prepare_dirs:
	@echo "Preparing filesystem..."
	$(CP) $(GRUB_CFG) $(ROOT_FS)/boot/grub/
	@echo "Filesystem preparation completed."

# Step 6: Customize rootfs (NEW)
customize-rootfs:
	@echo "Customizing rootfs for Ubuntu-style theming and Flatpak..."
	$(CHROOT) /bin/bash -c " \
		apt-get update && \
		apt-get install -y flatpak gnome-tweaks yaru-theme-gtk && \
		flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
		flatpak install -y --noninteractive com.heroicgameslauncher.hgl com.valvesoftware.Steam && \
		gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM \
	"
	@echo "Rootfs customization complete."

# Step 7: Build the ISO
build_iso:
	@echo "Building Ubuntu MikaOS ISO..."
	$(MKISOFS) -o $(ISO_NAME) \
		-b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table \
		$(ROOT_FS)
	@echo "Ubuntu MikaOS ISO created successfully: $(ISO_NAME)"

# Step 8: Clean output directory and fetched files
clean:
	@echo "Cleaning output directory and fetched files..."
	$(RM) $(OUTPUT_DIR)
	$(RM) $(FILES_DIR)

# Help
help:
	@echo "Makefile targets:"
	@echo "  all              - Full build process (folders, deps, files, ISO)"
	@echo "  buildfl          - Create folders"
	@echo "  get-deps         - Install system dependencies"
	@echo "  fetch-files      - Fetch apps/kernel from config"
	@echo "  prepare_dirs     - Copy GRUB config"
	@echo "  customize-rootfs - Add Flatpak, themes, and Ubuntu-style dock (NEW)"
	@echo "  build_iso        - Generate final ISO"
	@echo "  clean            - Remove build artifacts"
	@echo "  help             - Show this message"

.PHONY: all buildfl get-deps fetch-files prepare_dirs customize-rootfs build_iso clean help
