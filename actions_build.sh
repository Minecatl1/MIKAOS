#!/usr/bin/env bash
# actions_build.sh - Build custom Arch Linux ISO
# Usage: chmod +x actions_build.sh && ./actions_build.sh

set -e -u

# --- Determine paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# If running in GitHub Actions, use GITHUB_WORKSPACE
if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    REPO_ROOT="$GITHUB_WORKSPACE"
fi

PROFILE_DIR="$REPO_ROOT/archlive"
WORK_DIR="/tmp/archiso-tmp"
OUTPUT_DIR="$REPO_ROOT"

# --- Optional: Custom tooling (if you have these utilities) ---
# source "${PROFILE_DIR}/utilities/directories.sh" 2>/dev/null || true
# source "${PROFILE_DIR}/utilities/custom_tools.sh" 2>/dev/null || true
# run_once update_archscripts || true
# run_once make_local_repo || true

# --- Ensure required packages are installed ---
echo "==> Checking build dependencies..."
if ! command -v mkarchiso &>/dev/null; then
    echo "Error: archiso not installed. Run: sudo pacman -S archiso"
    exit 1
fi

# --- Copy bootloader files from system archiso (if not already present) ---
echo "==> Preparing bootloader files..."
# For BIOS / SYSLINUX
if [[ ! -d "$PROFILE_DIR/syslinux" ]]; then
    cp -r /usr/share/archiso/configs/releng/syslinux "$PROFILE_DIR/"
    echo "  -> Copied syslinux from system releng profile."
fi

# For UEFI / GRUB (if using uefi.grub)
if [[ ! -d "$PROFILE_DIR/grub" && -d /usr/share/archiso/configs/releng/grub ]]; then
    cp -r /usr/share/archiso/configs/releng/grub "$PROFILE_DIR/"
    echo "  -> Copied grub from system releng profile."
fi

# For legacy efiboot (if using systemd-boot)
if [[ ! -d "$PROFILE_DIR/efiboot" ]]; then
    cp -r /usr/share/archiso/configs/releng/efiboot "$PROFILE_DIR/"
    echo "  -> Copied efiboot from system releng profile."
fi

# --- Build the ISO ---
echo "==> Building ISO..."
mkdir -p "$WORK_DIR"
mkarchiso -v -w "$WORK_DIR" -o "$OUTPUT_DIR" "$PROFILE_DIR"

# --- Cleanup and finish ---
echo "==> Build completed successfully!"
echo "ISO file(s) located in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.iso

# Optional: wrap_up function if you have custom cleanup
# wrap_up
