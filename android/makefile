# Makefile for setting up a custom Android OS

# Variables
DESKTOP_ENVIRONMENT := ubuntu-desktop
WIFI_PACKAGE := network-manager
BLUETOOTH_PACKAGE := bluez
STEAM_REPO := multiverse
STEAM_PACKAGE := steam

# Default target
all: install-android install-desktop install-wifi install-bluetooth install-steam

# Install Android OS Components
install-android:
	@echo "Setting up Android OS components..."
	mkdir -p data/media/PlexMedia
	cd vendor/plex && \
	adb install Plex.apk
	cd vendor/protodactyl && \
	adb install pterodactyl.apk
	cd vendor/steam && \
	adb install SteamMobile.apk

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

# Install Steam
install-steam:
	@echo "Adding Steam repository..."
	sudo add-apt-repository -y $(STEAM_REPO)
	sudo apt update
	@echo "Installing Steam..."
	sudo apt install -y $(STEAM_PACKAGE)

# Clean
clean:
	@echo "Cleaning up..."
	sudo apt autoremove -y
	sudo apt clean

# Help
help:
	@echo "Makefile targets:"
	@echo "  all              - Install all components"
	@echo "  install-android  - Install Android OS components"
	@echo "  install-desktop  - Install desktop environment"
	@echo "  install-wifi     - Install WiFi"
	@echo "  install-bluetooth- Install Bluetooth"
	@echo "  install-steam    - Install Steam"
	@echo "  clean            - Clean up unnecessary packages"

.PHONY: all install-android install-desktop install-wifi install-bluetooth install-steam clean help
