#!/usr/bin/env bash
# install-arch.sh - Install custom Arch Linux to a mounted drive
# Usage: Run as root from the live environment after mounting target partition(s)

set -eu

# --- Paths within the live environment ---
BASE_DIR="/root/ArchScripts"                  # Where this script and config reside
INSTALL_SCRIPTS_DIR="/root/ArchScripts/install_scripts"   # Scripts to copy into target system
USER_SCRIPTS_DIR="/root/ArchScripts/user_scripts"         # User scripts to copy
ENV_PATH="${BASE_DIR}/install.conf"           # Configuration file
MOUNT_POINT="${MOUNT_POINT:-/mnt}"            # Target mount point (can be overridden)
CACHE_DIR="/custom_repo"                      # Local package cache (if using offline install)

# --- Source common functions if available ---
if [[ -f "${BASE_DIR}/install_scripts/install.sh" ]]; then
    source "${BASE_DIR}/install_scripts/install.sh"
else
    # Fallback printing functions
    print_message() { echo -e "\e[1;34m==>\e[0m $*"; }
    print_success() { echo -e "\e[1;32m==>\e[0m $*"; }
    print_warning() { echo -e "\e[1;33m==>\e[0m $*"; }
    print_failure() { echo -e "\e[1;31m==>\e[0m $*"; }
    print_trailing() { echo -ne "\e[1;34m==>\e[0m $*"; }
fi

# --- Setup pacman to use local repository (optional offline install) ---
setup_pacman_custom() {
    if [[ -d "$CACHE_DIR" ]]; then
        print_message "Configuring pacman to use local package cache..."
        cat <<-EOF > /etc/pacman.conf
[options]
CacheDir = ${CACHE_DIR}
Color
CheckSpace
ParallelDownloads = 5

[custom]
SigLevel = Optional TrustAll
Server = file://${CACHE_DIR}

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
        print_success "Pacman configured for offline installation."
    else
        print_warning "Local package cache not found. Using online repositories."
    fi
}

# --- Check if target drive is mounted ---
check_mounted_drive() {
    if findmnt -M "$MOUNT_POINT" &>/dev/null; then
        print_success "Drive mounted at $MOUNT_POINT."
    else
        print_failure "Drive is NOT mounted at $MOUNT_POINT!"
        print_warning "Mount your target root partition to '$MOUNT_POINT' and re-run this script."
        exit 1
    fi
}

# --- Prompt user to review/edit configuration ---
prompt_environment() {
    print_message "Installation will use configuration from: $ENV_PATH"
    print_warning "Ensure the settings are correct before proceeding!"

    if [[ ! -f "$ENV_PATH" ]]; then
        print_warning "Configuration file not found. Creating default..."
        cat <<-EOF > "$ENV_PATH"
# Installation configuration
DESKTOP_ENV="xfce4"
BOOTLOADER="grub"
VIDEO_DRIVERS="mesa"
HOSTNAME="custom-arch"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"
EOF
    fi

    print_trailing "Edit $ENV_PATH? ((Y)es / (n)o / e(x)it): "
    read -r ans
    case $ans in
        n|N)
            print_success "Proceeding with current settings..."
            ;;
        x|X)
            print_failure "Aborting installation."
            exit 1
            ;;
        *)
            ${EDITOR:-nano} "$ENV_PATH"
            print_message "--------------------------------------------"
            print_message "Press ENTER to continue, or Ctrl+C to abort."
            read -r
            ;;
    esac
    # Source the configuration
    source "$ENV_PATH"
}

# --- Copy installation scripts to target system ---
copy_configuration_scripts() {
    local target="${MOUNT_POINT}${INSTALL_SCRIPTS_DIR}"
    mkdir -p "$target"
    if [[ -d "${BASE_DIR}/install_scripts" ]]; then
        cp -v "${BASE_DIR}/install_scripts/"* "$target/"
        print_success "Installation scripts copied."
    else
        print_warning "No install_scripts directory found."
    fi
}

copy_user_scripts() {
    local target="${MOUNT_POINT}${USER_SCRIPTS_DIR}"
    mkdir -p "$target"
    if [[ -d "${BASE_DIR}/user_scripts" ]]; then
        cp -v "${BASE_DIR}/user_scripts/"* "$target/"
        print_success "User scripts copied."
    fi
}

# --- Run configuration inside chroot ---
configure_system() {
    copy_configuration_scripts
    copy_user_scripts

    print_warning ">>> Configuring system with $DESKTOP_ENV, $BOOTLOADER and $VIDEO_DRIVERS... <<<"

    # Determine shell to use inside chroot
    local mntshell="/bin/bash"
    if [[ -n "${USERSHELL:-}" ]] && [[ -f "${MOUNT_POINT}${USERSHELL}" ]]; then
        mntshell="$USERSHELL"
    fi

    # Execute config.sh inside the chroot
    arch-chroot "$MOUNT_POINT" "$mntshell" -c "
        cd ${INSTALL_SCRIPTS_DIR}
        ./config.sh
        rm -rf ${INSTALL_SCRIPTS_DIR} ${USER_SCRIPTS_DIR}
    "
    print_success "System configuration complete."
}

# --- Main installation routine ---
main() {
    print_message "=== Custom Arch Linux Installer ==="

    check_mounted_drive
    prompt_environment
    setup_pacman_custom   # Comment out if you always want online repos

    # install_system function should be defined in install.sh
    if declare -f install_system &>/dev/null; then
        install_system
    else
        print_failure "install_system function not found. Aborting."
        exit 1
    fi

    configure_system

    print_success "Installation finished! You may now reboot."
}

# --- Run only if executed directly and as root ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if (( EUID != 0 )); then
        print_failure "This script must be run with root privileges."
        exit 1
    fi
    main "$@"
fi
