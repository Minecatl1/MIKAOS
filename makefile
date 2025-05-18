.PHONY: all prepare build

all: prepare build

prepare:
    @echo "Optimizing for GitHub..."
    @mkdir -p build/filesystem

build:
    @echo "Building minimal system..."
    @bash scripts/fetch-deps.sh
    @bash scripts/chroot-setup.sh
    @bash scripts/build-iso.sh

clean:
    @rm -rf build output
