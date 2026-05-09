#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=".config"

echo "========================================="
echo "  MIKAOS Arch Configuration"
echo "========================================="
echo ""
echo "Desktop environment (choose 'none' for console-only):"
select DESKTOP in none openbox lxde xfce mate lxqt kde gnome; do
    case "$DESKTOP" in
        none|openbox|lxde|xfce|mate|lxqt|kde|gnome) break ;;
        *) echo "Invalid choice, pick 1-8." ;;
    esac
done

read -r -p "Include networking [Y/n]: " net
WITH_NETWORK=$([[ ! "$net" =~ ^[Nn] ]] && echo yes || echo no)
read -r -p "Include Wi-Fi support [y/N]: " wifi
WITH_WIFI=$([[ "$wifi" =~ ^[Yy] ]] && echo yes || echo no)
read -r -p "Include Bluetooth [y/N]: " bt
WITH_BLUETOOTH=$([[ "$bt" =~ ^[Yy] ]] && echo yes || echo no)
read -r -p "Include audio (PipeWire+JACK) [y/N]: " audio
WITH_AUDIO=$([[ "$audio" =~ ^[Yy] ]] && echo yes || echo no)

echo "Kernel type:"
echo "  1) Standard (defconfig)"
echo "  2) Minimal (tinyconfig + essentials)"
read -r -p "Choice [2]: " ktype
KERNEL_TYPE=$([[ "$ktype" != "1" ]] && echo minimal || echo standard)

read -r -p "Username [arch]: " USERNAME
USERNAME=${USERNAME:-arch}
read -r -s -p "Password for $USERNAME (empty = no password): " USER_PASS
echo ""
if [ -n "$USER_PASS" ]; then
    read -r -s -p "Confirm password: " USER_PASS2
    echo ""
    if [ "$USER_PASS" != "$USER_PASS2" ]; then
        echo "Passwords do not match."
        exit 1
    fi
fi
read -r -p "Hostname [archbox]: " HOSTNAME
HOSTNAME=${HOSTNAME:-archbox}
read -r -s -p "Root password (empty = disable root login): " ROOT_PASS
echo ""

echo "Kernel version:"
echo "  Enter an exact version. Patch releases such as 7.0.3 will download"
echo "  the matching upstream patch file and apply it to the base 7.0 tree."
read -r -p "Kernel version [7.0.3]: " KERNEL_VERSION
KERNEL_VERSION=${KERNEL_VERSION:-7.0.3}

cat > "$CONFIG_FILE" <<EOFCONFIG
DESKTOP=$DESKTOP
WITH_NETWORK=$WITH_NETWORK
WITH_WIFI=$WITH_WIFI
WITH_BLUETOOTH=$WITH_BLUETOOTH
WITH_AUDIO=$WITH_AUDIO
KERNEL_TYPE=$KERNEL_TYPE
USERNAME=$USERNAME
USER_PASS=$USER_PASS
HOSTNAME=$HOSTNAME
ROOT_PASS=$ROOT_PASS
KERNEL_VERSION=$KERNEL_VERSION
EOFCONFIG

echo "Configuration saved. Run 'make' to build."
