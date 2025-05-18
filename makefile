.PHONY: all clean

all:
	@echo "Building MIKAOS..."
	@bash scripts/fetch-deps.sh
	@bash scripts/build-iso.sh

clean:
	@rm -rf build output
