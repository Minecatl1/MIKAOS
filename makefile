.PHONY: all clean

all:
	@echo "Starting build process..."
	@mkdir -p output
	@bash scripts/fetch-deps.sh
	@bash scripts/build-iso.sh

clean:
	@rm -rf build output
