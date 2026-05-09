#!/usr/bin/env bash
set -euo pipefail

FLATPAK_USER_DIR="$HOME/.local/share/flatpak"
[ ! -d "$FLATPAK_USER_DIR" ] && flatpak config --user languages="*" &>/dev/null || true

usage() {
    cat <<EOFUSAGE
usp - MIKAOS Arch Unified Package Manager (pacman + Flatpak --user)
Commands:
  search <term>        Search pacman and Flathub
  install <pkg>        Install a package
  remove <pkg>         Remove a package
  run <pkg>            Launch an app
  update               Update pacman and Flatpak
  list                 Show installed packages
EOFUSAGE
    exit 1
}

flatpak_installed() { flatpak list --user --columns=application 2>/dev/null | grep -Fxq "$1"; }
pacman_installed() { pacman -Q "$1" &>/dev/null; }
find_flatpak_id() { flatpak search --user "$1" 2>/dev/null | awk 'NR==1 {print $1}'; }

search() {
    echo -e "\e[1m=== Pacman Packages ===\e[0m"
    pacman -Ss "$1" 2>/dev/null | head -20 || true
    echo -e "\n\e[1m=== Flatpak Applications (Flathub) ===\e[0m"
    flatpak search "$1" 2>/dev/null | head -20 || true
}

install() {
    local pkg="$1" pacman_candidate fp_id
    pacman_candidate=$(pacman -Ss "^${pkg}$" 2>/dev/null | awk 'NR==1 {print $1}')
    fp_id=$(find_flatpak_id "$pkg")
    if [ -z "$pacman_candidate" ] && [ -z "$fp_id" ]; then
        echo "Not found."
        exit 1
    fi
    if [ -z "$pacman_candidate" ]; then
        echo "Installing Flatpak (user): $fp_id"
        flatpak install --user -y flathub "$fp_id"
    elif [ -z "$fp_id" ]; then
        echo "Installing with pacman: $pacman_candidate"
        sudo pacman -S --noconfirm "$pacman_candidate"
    else
        echo "Found two options:"
        echo "  1) Pacman: $pacman_candidate"
        echo "  2) Flatpak: $fp_id"
        read -r -p "Choose [1/2]: " choice
        case "$choice" in
            1) sudo pacman -S --noconfirm "$pacman_candidate" ;;
            2) flatpak install --user -y flathub "$fp_id" ;;
            *) echo "Invalid"; exit 1 ;;
        esac
    fi
}

remove() {
    local pkg="$1" fp_id
    if pacman_installed "$pkg"; then
        sudo pacman -R --noconfirm "$pkg" && echo "Removed with pacman: $pkg"
        return
    fi
    fp_id=$(find_flatpak_id "$pkg")
    if [ -n "$fp_id" ] && flatpak_installed "$fp_id"; then
        flatpak uninstall --user -y "$fp_id" && echo "Removed Flatpak: $fp_id"
        return
    fi
    echo "Not installed."
    exit 1
}

run() {
    local pkg="$1" desktop fp_id
    desktop=$(find /usr/share/applications -name "*${pkg}*.desktop" 2>/dev/null | head -1)
    if [ -n "$desktop" ]; then
        gtk-launch "$(basename "$desktop" .desktop)" 2>/dev/null || exit 1
        return
    fi
    fp_id=$(find_flatpak_id "$pkg")
    if [ -n "$fp_id" ] && flatpak_installed "$fp_id"; then
        flatpak run --user "$fp_id"
        return
    fi
    if command -v "$pkg" &>/dev/null; then
        "$pkg"
        return
    fi
    echo "No executable found for '$pkg'."
    exit 1
}

update() {
    echo "Updating pacman..."
    sudo pacman -Syu --noconfirm
    echo "Updating Flatpak..."
    flatpak update --user -y
}

list() {
    echo "=== Pacman explicitly installed ==="
    pacman -Qe 2>/dev/null || echo "(unknown baseline)"
    echo -e "\n=== Flatpak (user) ==="
    flatpak list --user --columns=application,name 2>/dev/null || echo "none"
}

[ $# -lt 1 ] && usage
cmd="$1"
shift
case "$cmd" in
    search) search "$@" ;;
    install) install "$@" ;;
    remove) remove "$@" ;;
    run) run "$@" ;;
    update) update ;;
    list) list ;;
    *) usage ;;
esac
