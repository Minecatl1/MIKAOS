# Makefile for building MikaOS ISO,
# downloading required assets,
# and installing necessary dependencies.

# Directories and ISO settings
OUTPUT_DIR := output
ISO_NAME := mikaos.iso
ROOT_FS := build/filesystem
GRUB_CFG := build/grub_config/grub.cfg

# Download variables for assets
CHROME_DEB_URL := https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
CHROME_DEB_FILE := google-chrome-stable_current_amd64.deb

HEROIC_URL := https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest/download/HeroicSetup.AppImage
HEROIC_FILE := HeroicSetup.AppImage

# Tools (make sure these are installed)
MKISOFS := genisoimage
MKDIR := mkdir -p
CP := cp
RM := rm -rf

# Default target: First, install dependencies, then download assets, prepare directories, and build the ISO.
all: get-deps download-all prepare_dirs build_iso

# New target to get/install dependencies (you can add more tools if needed)
get-deps:
    @echo "Installing required dependencies..."
    # Update package lists and install dependencies. Adjust package names if needed.
    sudo apt update && sudo apt install -y genisoimage wget grub-pc-bin flatpak
    @echo "Dependencies installed."

# Target to download all required assets
download-all: download-chrome download-heroic

download-chrome:
    @echo "Downloading Google Chrome..."
    wget $(CHROME_DEB_URL) -O $(CHROME_DEB_FILE)

download-heroic:
    @echo "Downloading Heroic Games Launcher..."
    wget $(HEROIC_URL) -O $(HEROIC_FILE)

# Prepare the build directories and copy boot configuration files
prepare_dirs:
    @echo "Preparing directories..."
    $(MKDIR) $(OUTPUT_DIR)
    $(MKDIR) $(ROOT_FS)/boot/grub
    @echo "Copying GRUB configuration..."
    $(CP) $(GRUB_CFG) $(ROOT_FS)/boot/grub/

# Build the MikaOS ISO using the root filesystem and GRUB bootloader information
build_iso:
    @echo "Building the ISO..."
    $(MKISOFS) -o $(OUTPUT_DIR)/$(ISO_NAME) \
        -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table \
        $(ROOT_FS)
    @echo "ISO successfully built: $(OUTPUT_DIR)/$(ISO_NAME)"

# Clean: remove output directory and downloaded assets
clean:
    @echo "Cleaning up generated files..."
    $(RM) $(OUTPUT_DIR)
    $(RM) $(CHROME_DEB_FILE) $(HEROIC_FILE)

# Help: list available targets and their descriptions
help:
    @echo "Makefile targets:"
    @echo "  all            - Get dependencies, download assets, prepare directories, and build MikaOS ISO"
    @echo "  get-deps       - Install required build dependencies using apt"
    @echo "  download-all   - Download all required assets (Chrome & Heroic)"
    @echo "  download-chrome- Download Google Chrome package from the specified URL"
    @echo "  download-heroic- Download Heroic Games Launcher AppImage from GitHub"
    @echo "  prepare_dirs   - Create necessary directories and copy GRUB configuration"
    @echo "  build_iso      - Build the MikaOS ISO using the configured filesystem"
    @echo "  clean          - Remove generated output files and downloaded assets"
    @echo "  help           - Display this help message"

.PHONY: all get-deps download-all download-chrome download-heroic prepare_dirs build_iso clean help
