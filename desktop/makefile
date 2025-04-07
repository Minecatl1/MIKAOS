# Makefile for building Ubuntu MikaOS ISO

# Output and file paths
ISO_NAME := output/mikaos.iso
ROOT_FS := build/filesystem
FILES_DIR := files
OUTPUT_DIR := output
GRUB_CFG := build/grub_config/grub.cfg
Bui := build/filesystem/boot/grub/

# URLs for dependencies
STEAM_URL := https://repo.steampowered.com/steam/archive/stable/steam_latest.deb
CHROME_URL := https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
HEROIC_URL := https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.16.1/Heroic-2.16.1-linux-x86_64.AppImage

# Tools
MKISOFS := genisoimage
MKDIR := mkdir -p
CP := cp
RM := rm -rf

# Default target
all: buildfl get-deps fetch-files prepare_dirs build_iso

# Command to create all necessary folders
buildfl:
	@echo "Creating required folders..."
	$(MKDIR) $(FILES_DIR)
	$(MKDIR) $(ROOT_FS)/boot/grub
	$(MKDIR) $(ROOT_FS)/usr/local/bin
	$(MKDIR) $(OUTPUT_DIR)
	@echo "All folders created successfully!"

# Install dependencies from requirements.txt
get-deps:
	@echo "Installing dependencies from requirements.txt..."
	@xargs -a requirements.txt sudo apt install -y
	@echo "Configuring Bluetooth and Wi-Fi..."
	sudo systemctl enable bluetooth
	sudo systemctl enable NetworkManager

# Fetch required files (Steam, Chrome, Heroic, Kernel, Initramfs)
fetch-files:
	@echo "Fetching required files..."
	$(MKDIR) $(FILES_DIR)
	@echo "Downloading Steam setup..."
	wget -O $(FILES_DIR)/steamsetup.deb $(STEAM_URL)
	@echo "Downloading Google Chrome .deb..."
	wget -O $(FILES_DIR)/google-chrome.deb $(CHROME_URL)
	@echo "Downloading Heroic Games Launcher AppImage..."
	wget -O $(FILES_DIR)/heroicsetup.appimage $(HEROIC_URL)
	@echo "Downloading kernel archive..."
	wget -O $(FILES_DIR)/kernel_cache.zip https://github.com/Minecatl1/linux_binary_cache/archive/refs/tags/1.0.zip
	@echo "Unzipping kernel archive..."
	unzip -o $(FILES_DIR)/kernel_cache.zip -d $(FILES_DIR)
	@echo "Moving vmlinuz-5.15.0-105 to the correct location..."
	$(MKDIR) $(ROOT_FS)/boot
	mv $(FILES_DIR)/linux_binary_cache-1.0/vmlinuz-5.15.0-105 $(ROOT_FS)/boot/vmlinuz-linux
	wget -o $(Bui)/stage2_eltorito https://github.com/littleosbook/littleosbook/raw/refs/heads/master/files/stage2_eltorito
	
# Prepare filesystem and directories
prepare_dirs:
	@echo "Preparing filesystem..."
	$(CP) $(GRUB_CFG) $(ROOT_FS)/boot/grub/
	@echo "Installing applications into filesystem..."
	sudo dpkg -i $(FILES_DIR)/google-chrome.deb || sudo apt install -f -y
	sudo dpkg -i $(FILES_DIR)/steamsetup.deb || sudo apt install -f -y
	chmod +x $(FILES_DIR)/heroicsetup.appimage
	$(CP) $(FILES_DIR)/heroicsetup.appimage $(ROOT_FS)/usr/local/bin/heroic

# Build the ISO
build_iso:
	@echo "Building Ubuntu MikaOS ISO..."
	$(MKISOFS) -o $(ISO_NAME) \
		-b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table \
		$(ROOT_FS)
	@echo "Ubuntu MikaOS ISO created successfully: $(ISO_NAME)"

# Clean output directory and fetched files
clean:
	@echo "Cleaning output directory and fetched files..."
	$(RM) $(OUTPUT_DIR)
	$(RM) $(FILES_DIR)

# Help
help:
	@echo "Makefile targets:"	
	@echo "  all         - Create folders, install dependencies, fetch files, prepare filesystem, and build ISO"
	@echo "  buildfl     - Create all necessary folders"
	@echo "  get-deps    - Install dependencies from requirements.txt"
	@echo "  fetch-files - Download kernel, initramfs, Steam, Chrome, and Heroic installers"
	@echo "  prepare_dirs- Prepare filesystem and directories"
	@echo "  build_iso   - Build Ubuntu MikaOS ISO"
	@echo "  clean       - Clean output files and fetched files"
	@echo "  help        - Display this help message"

.PHONY: all buildfl get-deps fetch-files prepare_dirs build_iso clean help