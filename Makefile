SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all

PROJECT_NAME      ?= mikaos-arch
ROOTFS            ?= $(CURDIR)/rootfs
BUILD_DIR         ?= $(CURDIR)/build
ISODIR            ?= $(CURDIR)/iso
OUTPUT_DIR        ?= $(CURDIR)/out
ISO_DATE          ?= $(shell date +%Y%m%d)
ISO_NAME          ?= $(PROJECT_NAME)-$(ISO_DATE).iso
ISO_PATH          ?= $(OUTPUT_DIR)/$(ISO_NAME)
CONFIG_FILE       ?= $(CURDIR)/.config
DOCKER_FILE       ?= $(CURDIR)/Dockerfile.arch
DOCKER_IMAGE      ?= $(PROJECT_NAME)-builder
SKIP_HOST_CHECK   ?= 0

QEMU              ?= qemu-system-x86_64
QEMU_MEM          ?= 2048
QEMU_CPUS         ?= 2
QEMU_TIMEOUT      ?= 45
QEMU_ACCEL        ?= kvm:tcg
QEMU_DISPLAY      ?= none
QEMU_NET          ?= none
OVMF_CODE         ?= $(firstword \
  $(wildcard /usr/share/OVMF/OVMF_CODE.fd) \
  $(wildcard /usr/share/OVMF/OVMF_CODE_4M.fd) \
  $(wildcard /usr/share/edk2/x64/OVMF_CODE.fd) \
  $(wildcard /usr/share/edk2-ovmf/x64/OVMF_CODE.fd) \
  $(wildcard /usr/share/qemu/OVMF.fd))
OVMF_VARS_TEMPLATE ?= $(firstword \
  $(wildcard /usr/share/OVMF/OVMF_VARS.fd) \
  $(wildcard /usr/share/OVMF/OVMF_VARS_4M.fd) \
  $(wildcard /usr/share/edk2/x64/OVMF_VARS.fd) \
  $(wildcard /usr/share/edk2-ovmf/x64/OVMF_VARS.fd))
OVMF_VARS         ?= $(BUILD_DIR)/OVMF_VARS.fd

SUDO := $(shell if [ "$$(id -u)" -eq 0 ]; then echo ''; else echo 'sudo'; fi)

ifneq ("$(wildcard $(CONFIG_FILE))","")
include $(CONFIG_FILE)
endif

DESKTOP          ?= openbox
WITH_NETWORK     ?= yes
WITH_WIFI        ?= no
WITH_BLUETOOTH   ?= no
WITH_AUDIO       ?= no
KERNEL_TYPE      ?= minimal
USERNAME         ?= arch
USER_PASS        ?=
HOSTNAME         ?= archbox
ROOT_PASS        ?=
KERNEL_VERSION   ?= 7.0.3

# GNU Make imports environment variables. Keep the project default stable unless
# HOSTNAME was supplied by .config, a makefile, or the command line.
ifeq ($(origin HOSTNAME), environment)
HOSTNAME := archbox
endif

ifeq ($(DESKTOP),none)
DM :=
DM_PKG :=
else ifeq ($(DESKTOP),kde)
DM := sddm
DM_PKG := sddm
else ifeq ($(DESKTOP),gnome)
DM := gdm
DM_PKG := gdm
else ifeq ($(DESKTOP),hyprland)
DM := sddm
DM_PKG := sddm
else
DM := lightdm
DM_PKG := lightdm lightdm-gtk-greeter
endif

USER_GROUPS := wheel,network,video
ifeq ($(WITH_AUDIO),yes)
USER_GROUPS := $(USER_GROUPS),audio
endif
ifeq ($(WITH_BLUETOOTH),yes)
USER_GROUPS := $(USER_GROUPS),bluetooth
endif

HOST_OS := $(shell if [ -r /etc/os-release ]; then . /etc/os-release && echo $$ID; else uname -s | tr '[:upper:]' '[:lower:]'; fi)
ifeq ($(HOST_OS),arch)
BUILD_METHOD ?= native
else ifeq ($(HOST_OS),manjaro)
BUILD_METHOD ?= native
else
BUILD_METHOD ?= docker
endif

.PHONY: all help print-config configure host-deps native-deps docker-image docker-build \
        base kernel desktop audio flatpak usp accounts iso native-iso container \
        check check-config check-qemu-tools qemu-bios qemu-uefi test-qemu \
        test-qemu-bios test-qemu-uefi clean distclean

all: iso

help: ## Show available targets.
	@awk 'BEGIN {FS = ":.*##"; print "MIKAOS Arch build targets:"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

print-config: ## Print effective build settings.
	@printf 'PROJECT_NAME=%s\nROOTFS=%s\nISODIR=%s\nOUTPUT_DIR=%s\nISO_PATH=%s\nBUILD_METHOD=%s\nDESKTOP=%s\nKERNEL_VERSION=%s\nQEMU=%s\nOVMF_CODE=%s\n' \
	  '$(PROJECT_NAME)' '$(ROOTFS)' '$(ISODIR)' '$(OUTPUT_DIR)' '$(ISO_PATH)' '$(BUILD_METHOD)' '$(DESKTOP)' '$(KERNEL_VERSION)' '$(QEMU)' '$(OVMF_CODE)'

check: check-config ## Run Makefile checks that do not require root or ISO build tools.
	@bash -n configure.sh
	@bash -n usp.sh
	@$(MAKE) --no-print-directory --dry-run test-qemu ISO_PATH=/tmp/$(ISO_NAME) OVMF_CODE=/tmp/OVMF_CODE.fd OVMF_VARS_TEMPLATE= >/dev/null
	@echo 'Makefile parse, script syntax, configuration validation, and QEMU recipe expansion passed.'

check-config: ## Validate configuration choices.
	@case '$(DESKTOP)' in none|openbox|lxde|xfce|mate|lxqt|kde|gnome|hyprland) ;; *) echo 'Invalid DESKTOP=$(DESKTOP)'; exit 1 ;; esac
	@case '$(WITH_NETWORK)' in yes|no) ;; *) echo 'Invalid WITH_NETWORK=$(WITH_NETWORK)'; exit 1 ;; esac
	@case '$(WITH_WIFI)' in yes|no) ;; *) echo 'Invalid WITH_WIFI=$(WITH_WIFI)'; exit 1 ;; esac
	@case '$(WITH_BLUETOOTH)' in yes|no) ;; *) echo 'Invalid WITH_BLUETOOTH=$(WITH_BLUETOOTH)'; exit 1 ;; esac
	@case '$(WITH_AUDIO)' in yes|no) ;; *) echo 'Invalid WITH_AUDIO=$(WITH_AUDIO)'; exit 1 ;; esac
	@case '$(KERNEL_TYPE)' in minimal|standard) ;; *) echo 'Invalid KERNEL_TYPE=$(KERNEL_TYPE)'; exit 1 ;; esac
	@echo 'Configuration values are valid.'

configure: configure.sh ## Run interactive configuration when .config is missing.
	@if [ ! -f '$(CONFIG_FILE)' ]; then \
		echo 'Running interactive configuration...'; \
		./configure.sh; \
	else \
		echo 'Configuration present. Run rm .config && make configure to reconfigure.'; \
	fi

host-deps: ## Install or verify host dependencies for the selected build method.
ifeq ($(BUILD_METHOD),docker)
	@echo "Building inside Docker because host OS '$(HOST_OS)' is not Arch."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo 'Docker is required for non-Arch hosts. Install Docker, then re-run make.'; \
		exit 1; \
	fi
	@$(SUDO) systemctl start docker 2>/dev/null || true
else
	@$(MAKE) --no-print-directory native-deps
endif

native-deps: ## Verify native Arch build dependencies are installed.
	@missing=0; \
	for cmd in pacstrap chroot mksquashfs grub-mkrescue wget tar curl xzcat patch; do \
		command -v "$$cmd" >/dev/null 2>&1 || { echo "missing native dependency: $$cmd"; missing=1; }; \
	done; \
	exit "$$missing"

$(DOCKER_FILE):
	@echo '==> Creating Dockerfile.arch...'
	@printf '%s\n' \
		'FROM archlinux:latest' \
		'RUN pacman -Syu --noconfirm && pacman -S --needed --noconfirm base-devel arch-install-scripts sudo git curl wget xz patch squashfs-tools xorriso grub mtools dosfstools libisoburn qemu-system-x86 edk2-ovmf && echo '\''%wheel ALL=(ALL) NOPASSWD: ALL'\'' >> /etc/sudoers && useradd -m -G wheel builder && mkdir -p /build && chown builder:builder /build' \
		'USER builder' \
		'WORKDIR /build' > '$@'

docker-image: $(DOCKER_FILE) ## Build the Arch builder container image.
	@echo "==> Building Docker image '$(DOCKER_IMAGE)'..."
	docker build -t '$(DOCKER_IMAGE)' -f '$(DOCKER_FILE)' .

docker-build: docker-image configure ## Run full ISO build inside an Arch container.
	@echo '==> Running full build inside Arch container...'
	docker run --rm --privileged \
		-v '$(CURDIR)':/build \
		'$(DOCKER_IMAGE)' \
		bash -lc "cd /build && make native-iso SKIP_HOST_CHECK=1 OUTPUT_DIR=/build/out ISO_NAME='$(ISO_NAME)'"
	@echo "==> Container finished. ISO: $(ISO_PATH)"

base: ## Bootstrap the Arch Linux root filesystem.
ifeq ($(SKIP_HOST_CHECK),0)
	@$(MAKE) --no-print-directory native-deps
endif
	@echo '==> Bootstrapping Arch Linux base system...'
	$(SUDO) mkdir -p '$(ROOTFS)'
	$(SUDO) pacstrap -K -c -M '$(ROOTFS)' base base-devel arch-install-scripts sudo --noconfirm
	$(SUDO) sed -i 's/^#ParallelDownloads/ParallelDownloads/' '$(ROOTFS)/etc/pacman.conf'

kernel: base ## Build and install the configured Linux kernel.
	@version='$(KERNEL_VERSION)'; \
	if [ "$$version" = latest ]; then \
		version="$$(curl -fsSL https://www.kernel.org 2>/dev/null | sed -n 's/.*latest_link.*linux-\([0-9][^<]*\)\.tar.*/\1/p' | head -1)"; \
	fi; \
	if [ -z "$$version" ]; then echo 'Could not resolve latest kernel version; set KERNEL_VERSION=x.y.z'; exit 1; fi; \
	echo "==> Installing kernel build dependencies..."; \
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm bc xmlto kmod inetutils libelf git cpio curl; \
	if [ -d './patches' ]; then echo 'Copying patches to build environment...'; $(SUDO) cp -r ./patches '$(ROOTFS)/tmp/patches'; fi; \
	major="$${version%%.*}"; \
	rest="$${version#*.}"; minor="$${rest%%.*}"; base_version="$$major.$$minor"; \
	patchlevel=; [ "$$version" = "$$base_version" ] || patchlevel="$${version#$$base_version.}"; \
	$(SUDO) mkdir -p '$(ROOTFS)/usr/src'; \
	if [ -n "$$patchlevel" ]; then \
		echo "==> Downloading Linux $$base_version and upstream patch $$version..."; \
		if wget -q -O "linux-$$base_version.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v$$major.x/linux-$$base_version.tar.xz" && \
		   wget -q -O "patch-$$version.xz" "https://cdn.kernel.org/pub/linux/kernel/v$$major.x/patch-$$version.xz"; then \
			$(SUDO) tar -xf "linux-$$base_version.tar.xz" -C '$(ROOTFS)/usr/src'; \
			xzcat "patch-$$version.xz" | $(SUDO) patch -d '$(ROOTFS)/usr/src/linux-'"$$base_version" -p1; \
			$(SUDO) mv '$(ROOTFS)/usr/src/linux-'"$$base_version" '$(ROOTFS)/usr/src/linux-'"$$version"; \
		else \
			echo "==> Patch path unavailable; falling back to full Linux $$version tarball..."; \
			rm -f "linux-$$base_version.tar.xz" "patch-$$version.xz"; \
			wget -q -O "linux-$$version.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v$$major.x/linux-$$version.tar.xz"; \
			$(SUDO) tar -xf "linux-$$version.tar.xz" -C '$(ROOTFS)/usr/src'; \
		fi; \
	else \
		echo "==> Downloading Linux kernel $$version..."; \
		wget -q -O "linux-$$version.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v$$major.x/linux-$$version.tar.xz"; \
		$(SUDO) tar -xf "linux-$$version.tar.xz" -C '$(ROOTFS)/usr/src'; \
	fi; \
	cleanup() { $(SUDO) umount -R '$(ROOTFS)/proc' 2>/dev/null || true; $(SUDO) umount -R '$(ROOTFS)/sys' 2>/dev/null || true; $(SUDO) umount -R '$(ROOTFS)/dev' 2>/dev/null || true; }; \
	trap cleanup EXIT; \
	$(SUDO) mount -t proc none '$(ROOTFS)/proc'; \
	$(SUDO) mount -t sysfs none '$(ROOTFS)/sys'; \
	$(SUDO) mount --bind /dev '$(ROOTFS)/dev'; \
	$(SUDO) chroot '$(ROOTFS)' bash -lc "cd /usr/src/linux-$$version && if [ -d /tmp/patches ]; then for patch in /tmp/patches/*.patch; do [ -e \"\$$patch\" ] || continue; patch -Np1 < \"\$$patch\"; done; fi"; \
	if [ '$(KERNEL_TYPE)' = minimal ]; then \
		$(SUDO) chroot '$(ROOTFS)' bash -lc "cd /usr/src/linux-$$version && make tinyconfig && scripts/config --enable CONFIG_64BIT --enable CONFIG_X86_64 --enable CONFIG_PCI --enable CONFIG_BLK_DEV_SD --enable CONFIG_ATA --enable CONFIG_SATA_AHCI --enable CONFIG_EXT4_FS --enable CONFIG_OVERLAY_FS --enable CONFIG_ISO9660_FS --enable CONFIG_NET --enable CONFIG_INET --enable CONFIG_NETDEVICES --enable CONFIG_E1000 --enable CONFIG_E1000E --enable CONFIG_VIRTIO_BLK --enable CONFIG_VIRTIO_NET --enable CONFIG_USB_XHCI_HCD --enable CONFIG_USB_STORAGE --enable CONFIG_KEYBOARD_ATKBD --enable CONFIG_INPUT_MOUSE --enable CONFIG_FB --enable CONFIG_DRM --enable CONFIG_DRM_SIMPLEDRM --enable CONFIG_TTY --enable CONFIG_SERIAL_8250 --enable CONFIG_SERIAL_8250_CONSOLE && make olddefconfig && make -j\$$(nproc) && make modules_install && make install"; \
	else \
		$(SUDO) chroot '$(ROOTFS)' bash -lc "cd /usr/src/linux-$$version && make defconfig && make -j\$$(nproc) && make modules_install && make install"; \
	fi; \
	rm -f "linux-$$version.tar.xz" "linux-$$base_version.tar.xz" "patch-$$version.xz"

desktop: base ## Install desktop, display-manager, and connectivity packages.
	@echo '==> Installing $(DESKTOP) and connectivity...'
ifeq ($(WITH_NETWORK),yes)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm dhcpcd
ifeq ($(WITH_WIFI),yes)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm networkmanager network-manager-applet
	$(SUDO) chroot '$(ROOTFS)' systemctl enable NetworkManager
else
	$(SUDO) chroot '$(ROOTFS)' systemctl enable dhcpcd
endif
endif
ifeq ($(WITH_BLUETOOTH),yes)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm bluez bluez-utils blueman
	$(SUDO) chroot '$(ROOTFS)' systemctl enable bluetooth
endif
ifneq ($(DESKTOP),none)
ifeq ($(DESKTOP),hyprland)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm xorg-xwayland
else
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm xorg-server xorg-xinit xorg-xrandr
endif
endif
ifeq ($(DESKTOP),openbox)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm openbox obconf tint2 feh pcmanfm xterm
else ifeq ($(DESKTOP),lxde)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm lxde
else ifeq ($(DESKTOP),xfce)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm xfce4 xfce4-goodies
else ifeq ($(DESKTOP),mate)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm mate
else ifeq ($(DESKTOP),lxqt)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm lxqt
else ifeq ($(DESKTOP),kde)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm plasma-desktop
else ifeq ($(DESKTOP),gnome)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm gnome
else ifeq ($(DESKTOP),hyprland)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm hyprland xdg-desktop-portal-hyprland waybar wofi kitty grim slurp wl-clipboard polkit xorg-xwayland
endif
ifneq ($(DESKTOP),none)
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm $(DM_PKG)
	$(SUDO) chroot '$(ROOTFS)' systemctl enable $(DM)
endif

audio: base ## Install PipeWire audio when WITH_AUDIO=yes.
ifeq ($(WITH_AUDIO),yes)
	@echo '==> Installing PipeWire + JACK...'
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm pipewire pipewire-jack pipewire-pulse wireplumber pavucontrol-qt alsa-utils
	$(SUDO) chroot '$(ROOTFS)' systemctl --global enable pipewire.service wireplumber.service pipewire-pulse.service
else
	@echo 'Skipping audio.'
endif

flatpak: base ## Install Flatpak and add Flathub.
	@echo '==> Installing Flatpak...'
	$(SUDO) chroot '$(ROOTFS)' pacman -S --needed --noconfirm flatpak
	$(SUDO) mkdir -p '$(ROOTFS)/var/lib/flatpak'
	@trap '$(SUDO) umount -R "$(ROOTFS)/proc" 2>/dev/null || true; $(SUDO) umount -R "$(ROOTFS)/sys" 2>/dev/null || true' EXIT; \
	$(SUDO) mount -t proc none '$(ROOTFS)/proc'; \
	$(SUDO) mount -t sysfs none '$(ROOTFS)/sys'; \
	$(SUDO) chroot '$(ROOTFS)' flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

usp: base usp.sh ## Install the unified package-manager helper.
	@echo '==> Installing usp...'
	$(SUDO) install -Dm755 usp.sh '$(ROOTFS)/usr/local/bin/usp'

accounts: base ## Create the configured user and hostname.
	@echo '==> Creating user $(USERNAME)...'
	@trap '$(SUDO) umount -R "$(ROOTFS)/proc" 2>/dev/null || true; $(SUDO) umount -R "$(ROOTFS)/sys" 2>/dev/null || true; $(SUDO) umount -R "$(ROOTFS)/dev" 2>/dev/null || true' EXIT; \
	$(SUDO) mount -t proc none '$(ROOTFS)/proc'; \
	$(SUDO) mount -t sysfs none '$(ROOTFS)/sys'; \
	$(SUDO) mount --bind /dev '$(ROOTFS)/dev'; \
	$(SUDO) chroot '$(ROOTFS)' useradd -m -s /bin/bash -G '$(USER_GROUPS)' '$(USERNAME)' 2>/dev/null || true; \
	if [ -n '$(USER_PASS)' ]; then $(SUDO) chroot '$(ROOTFS)' bash -lc "echo '$(USERNAME):$(USER_PASS)' | chpasswd"; fi; \
	if [ -n '$(ROOT_PASS)' ]; then $(SUDO) chroot '$(ROOTFS)' bash -lc "echo 'root:$(ROOT_PASS)' | chpasswd"; else $(SUDO) chroot '$(ROOTFS)' passwd -l root; fi; \
	$(SUDO) chroot '$(ROOTFS)' bash -lc "echo '$(USERNAME) ALL=(ALL) ALL' > /etc/sudoers.d/$(USERNAME)"
	@echo '==> Setting hostname to $(HOSTNAME)...'
	@echo '$(HOSTNAME)' | $(SUDO) tee '$(ROOTFS)/etc/hostname' >/dev/null
	@$(SUDO) chroot '$(ROOTFS)' bash -lc "grep -q '^127.0.1.1 ' /etc/hosts || echo '127.0.1.1 $(HOSTNAME).localdomain $(HOSTNAME)' >> /etc/hosts"

iso: configure host-deps ## Build the ISO using Docker on non-Arch hosts or natively on Arch.
ifeq ($(BUILD_METHOD),docker)
	$(MAKE) docker-build
else
	$(MAKE) native-iso
endif

native-iso: kernel desktop audio flatpak usp accounts ## Create a hybrid BIOS+UEFI ISO image.
	@echo '==> Cleaning package cache...'
	$(SUDO) chroot '$(ROOTFS)' pacman -Scc --noconfirm 2>/dev/null || true
	@echo '==> Creating bootable hybrid BIOS+UEFI ISO image...'
	@mkdir -p '$(ISODIR)/live' '$(ISODIR)/boot/grub' '$(OUTPUT_DIR)'
	$(SUDO) mksquashfs '$(ROOTFS)' '$(ISODIR)/live/filesystem.squashfs' -comp xz -e boot
	$(SUDO) cp $$(find '$(ROOTFS)/boot' -maxdepth 1 -type f -name 'vmlinuz*' | sort | tail -n 1) '$(ISODIR)/live/vmlinuz'
	$(SUDO) cp $$(find '$(ROOTFS)/boot' -maxdepth 1 -type f \( -name 'initramfs*.img' -o -name 'initrd*.img' \) | sort | tail -n 1) '$(ISODIR)/live/initrd'
	@printf '%s\n' \
		'set default=0' \
		'set timeout=5' \
		'insmod all_video' \
		'insmod serial' \
		'serial --speed=115200 --unit=0 || true' \
		'terminal_input console serial' \
		'terminal_output console serial' \
		'menuentry "MIKAOS Arch Live (BIOS/UEFI)" {' \
		'    set gfxpayload=keep' \
		'    linux /live/vmlinuz boot=live root=live:CDLABEL=MIKAOS_ARCH quiet splash console=tty0 console=ttyS0,115200' \
		'    initrd /live/initrd' \
		'}' \
		'menuentry "MIKAOS Arch Live (safe graphics)" {' \
		'    set gfxpayload=text' \
		'    linux /live/vmlinuz boot=live root=live:CDLABEL=MIKAOS_ARCH nomodeset console=tty0 console=ttyS0,115200' \
		'    initrd /live/initrd' \
		'}' > '$(ISODIR)/boot/grub/grub.cfg'
	$(SUDO) grub-mkrescue -o '$(ISO_PATH)' '$(ISODIR)' -- -volid MIKAOS_ARCH
	@echo "ISO created: $(ISO_PATH)"

container: base kernel desktop audio flatpak usp accounts ## Create a rootfs tarball instead of an ISO.
	@echo '==> Creating rootfs tarball...'
	@mkdir -p '$(OUTPUT_DIR)'
	$(SUDO) tar -czpf '$(OUTPUT_DIR)/$(PROJECT_NAME)-rootfs.tar.gz' -C '$(ROOTFS)' .
	@echo "Container tarball: $(OUTPUT_DIR)/$(PROJECT_NAME)-rootfs.tar.gz"

check-qemu-tools: ## Verify QEMU and OVMF are available for local VM tests.
	@command -v '$(QEMU)' >/dev/null 2>&1 || { echo 'QEMU not found: $(QEMU)'; exit 1; }
	@test -n '$(OVMF_CODE)' || { echo 'OVMF_CODE not found; install OVMF/edk2-ovmf or set OVMF_CODE=...'; exit 1; }
	@echo 'QEMU and OVMF are available.'

qemu-bios: ## Boot ISO in QEMU BIOS mode. Override ISO_PATH=/path/to.iso if needed.
	@iso='$(ISO_PATH)'; \
	[ -f "$$iso" ] || { echo "ISO not found: $$iso"; echo 'Run make iso or pass ISO_PATH=/path/to.iso'; exit 1; }; \
	'$(QEMU)' -machine q35,accel='$(QEMU_ACCEL)' -m '$(QEMU_MEM)' -smp '$(QEMU_CPUS)' \
		-cdrom "$$iso" -boot d -net '$(QEMU_NET)' -serial mon:stdio -display '$(QEMU_DISPLAY)' -no-reboot

qemu-uefi: ## Boot ISO in QEMU UEFI mode with OVMF. Override ISO_PATH=/path/to.iso if needed.
	@iso='$(ISO_PATH)'; \
	[ -f "$$iso" ] || { echo "ISO not found: $$iso"; echo 'Run make iso or pass ISO_PATH=/path/to.iso'; exit 1; }; \
	[ -n '$(OVMF_CODE)' ] || { echo 'OVMF_CODE not found; install OVMF/edk2-ovmf or set OVMF_CODE=/path/to/OVMF_CODE.fd'; exit 1; }; \
	mkdir -p '$(BUILD_DIR)'; \
	uefi_drives=(-drive if=pflash,format=raw,readonly=on,file='$(OVMF_CODE)'); \
	if [ -n '$(OVMF_VARS_TEMPLATE)' ]; then cp -f '$(OVMF_VARS_TEMPLATE)' '$(OVMF_VARS)'; uefi_drives+=(-drive if=pflash,format=raw,file='$(OVMF_VARS)'); fi; \
	'$(QEMU)' -machine q35,accel='$(QEMU_ACCEL)' -m '$(QEMU_MEM)' -smp '$(QEMU_CPUS)' \
		"$${uefi_drives[@]}" -cdrom "$$iso" -boot d -net '$(QEMU_NET)' -serial mon:stdio -display '$(QEMU_DISPLAY)' -no-reboot

test-qemu: test-qemu-bios test-qemu-uefi ## Timed headless smoke test in both BIOS and UEFI modes.

test-qemu-bios: ## Timed BIOS smoke test; timeout means firmware/kernel kept running.
	@set +e; timeout '$(QEMU_TIMEOUT)'s $(MAKE) --no-print-directory qemu-bios ISO_PATH='$(ISO_PATH)' QEMU_DISPLAY='$(QEMU_DISPLAY)'; rc=$$?; \
	if [ $$rc -eq 0 ] || [ $$rc -eq 124 ]; then echo 'BIOS QEMU smoke test completed.'; exit 0; fi; exit $$rc

test-qemu-uefi: ## Timed UEFI smoke test; timeout means firmware/kernel kept running.
	@set +e; timeout '$(QEMU_TIMEOUT)'s $(MAKE) --no-print-directory qemu-uefi ISO_PATH='$(ISO_PATH)' QEMU_DISPLAY='$(QEMU_DISPLAY)'; rc=$$?; \
	if [ $$rc -eq 0 ] || [ $$rc -eq 124 ]; then echo 'UEFI QEMU smoke test completed.'; exit 0; fi; exit $$rc

clean: ## Remove generated rootfs, ISO staging, downloads, and generated Dockerfile.
	$(SUDO) rm -rf '$(ROOTFS)' '$(ISODIR)' '$(BUILD_DIR)' linux-*.tar.xz Dockerfile.arch

distclean: clean ## Remove generated output artifacts too.
	$(SUDO) rm -rf '$(OUTPUT_DIR)' mikaos-arch-rootfs.tar.gz
