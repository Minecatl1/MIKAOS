#!/bin/bash

apt update
apt upgrade

apt install -y \
  gnome-shell \
  gnome-session \
  gnome-control-center \
  gnome-terminal \
  nautilus \
  gnome-software \
  gnome-system-monitor \
  gnome-screenshot \
  gnome-calculator \
  gedit \
  gnome-disk-utility \
  eog \
  evince \
  gnome-characters \
  gnome-weather \
  gnome-maps \
  gnome-clocks \
  gnome-tweaks \
  gnome-backgrounds \
  gnome-contacts \
  gnome-font-viewer \
  gnome-logs \
  gnome-music \
  gnome-photos \
  gnome-sound-recorder \
  gnome-video-effects \
  gnome-calendar \
  gnome-dictionary \
  gnome-remote-desktop \
  gnome-shell-extensions \
  gnome-user-docs \
  gnome-user-share \
  gnome-keyring \
  gnome-color-manager \
  gnome-power-manager \
  gnome-flashback \
  gnome-nettool \
  gnome-sudoku \
  gnome-mahjongg \
  gnome-mines \
  gnome-chess \
  simple-scan \
  cheese \
  file-roller \
  seahorse \
  baobab \
  vinagre \
  blueman \
  network-manager-gnome

echo "All GNOME desktop components and apps have been installed."
