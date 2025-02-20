# Makefile for setting up a custom Desktop OS

# Variables
DESKTOP_DIR := desktop
PREINSTALL_DIR := $(DESKTOP_DIR)/preinstall
DESKTOP_ENVIRONMENT := ubuntu-desktop
WIFI_PACKAGE := network-manager
BLUETOOTH_PACKAGE := bluez
WINE_PACKAGE := wine
STEAM_SETUP_FILE := $(PREINSTALL_DIR)/SteamSetup.exe
ISO_IMAGE := MIKAOS.iso
ISO_DIR := $(DESKTOP_DIR)/iso
SCRIPTS_DIR := $(DESKTOP_DIR)/scripts

# Default target
all: install-desktop install-wifi install-bluetooth install-wine install-steam create-iso

# Install Desktop Environment
install-desktop:
	@echo "Installing desktop environment..."
	sudo apt update
	sudo apt install -y $(DESKTOP_ENVIRONMENT)

# Install WiFi
install-wifi:
	@echo "Installing WiFi..."
	sudo apt update
	sudo apt install -y $(WIFI_PACKAGE)

# Install Bluetooth
install-bluetooth:
	@echo "Installing Bluetooth..."
	sudo apt update
	sudo apt install -y $(BLUETOOTH_PACKAGE)
	sudo systemctl enable bluetooth
	sudo systemctl start bluetooth

# Install Wine
install-wine:
	@echo "Installing Wine for running .exe files..."
	sudo apt update
	sudo apt install -y $(WINE_PACKAGE)

# Install Steam using Steam setup .exe file
install-steam:
	@echo "Installing Steam using Wine..."
	if [ -f "$(STEAM_SETUP_FILE)" ]; then
		wine "$(STEAM_SETUP_FILE)"
	else
		@echo "Steam setup file not found in the preinstall folder. Please download it and place it in the preinstall folder."
	fi

# Create ISO Image
create-iso:
	@echo "Creating ISO image..."
	mkdir -p $(ISO_DIR)
	cp -r $(SCRIPTS_DIR) $(ISO_DIR)/
	genisoimage -o $(DESKTOP_DIR)/$(ISO_IMAGE) -r $(ISO_DIR)/

# Clean
clean:
	@echo "Cleaning up..."
	sudo apt autoremove -y
	sudo apt clean

# Help
help:
	@echo "Makefile targets:"
	@echo "  all              - Install all components and create ISO image"
	@echo "  install-desktop  - Install desktop environment"
	@echo "  install-wifi     - Install WiFi"
	@echo "  install-bluetooth- Install Bluetooth"
	@echo "  install-wine     - Install Wine"
	@echo "  install-steam    - Install Steam using the setup .exe file"
	@echo "  create-iso       - Create ISO image"
	@echo "  clean            - Clean up unnecessary packages"

.PHONY: all install-desktop install-wifi install-bluetooth install-wine install-steam create-iso clean help