# Lightweight Makefile for GitHub Actions
.PHONY: all prepare build

all: prepare build

prepare:
	@echo "Preparing build environment..."
	@sudo apt-get update
	@sudo apt-get install -y xorriso genisoimage squashfs-tools

build:
	@echo "Starting build..."
	@bash scripts/fetch-deps.sh
	@bash scripts/chroot-setup.sh
	@bash scripts/build-iso.sh

clean:
	@rm -rf build output
