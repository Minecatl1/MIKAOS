# Makefile with explicit error checking
.PHONY: all clean

all:
	@echo "Starting build process..."
	@mkdir -p output
	@echo "Fetching dependencies..."
	@bash -e scripts/fetch-deps.sh || (echo "Dependency fetch failed"; exit 1)
	@echo "Building ISO..."
	@bash -e scripts/build-iso.sh || (echo "ISO build failed"; exit 1)
	@echo "Build successful!"

clean:
	@echo "Cleaning..."
	@rm -rf build output
