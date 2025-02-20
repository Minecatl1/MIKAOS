#!/bin/bash

# Variables
DESKTOP_ENVIRONMENT="ubuntu-desktop"
WIFI_PACKAGE="network-manager"
BLUETOOTH_PACKAGE="bluez"
STEAM_REPO="multiverse"
STEAM_PACKAGE="steam"
WINE_PACKAGE="wine"
ISO_IMAGE="custom_os.iso"
ISO_DIR="iso"
SCRIPTS_DIR="scripts"

# Update and install desktop environment
echo "Installing desktop environment..."
sudo apt update
sudo apt install -y $DESKTOP_ENVIRONMENT

# Install WiFi package
echo "Installing WiFi..."
sudo apt install -y $WIFI_PACKAGE

# Install Bluetooth package
echo "Installing Bluetooth..."
sudo apt install -y $BLUETOOTH_PACKAGE
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Add Steam repository and install Steam
echo "Adding Steam repository..."
sudo add-apt-repository -y $STEAM_REPO
sudo apt update
echo "Installing Steam..."
sudo apt install -y $STEAM_PACKAGE

# Install Wine package for running .exe files
echo "Installing Wine..."
sudo apt install -y $WINE_PACKAGE

# Create ISO image
echo "Creating ISO image..."
mkdir -p $ISO_DIR
cp -r $SCRIPTS_DIR $ISO_DIR/
genisoimage -o $ISO_IMAGE -r $ISO_DIR/

echo "Installation and ISO creation complete."
