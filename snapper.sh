#!/bin/bash

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOGFILE="/var/log/snapper-setup.log"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

print_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}[STEP]${NC} $1"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_btrfs() {
    print_info "Checking if root filesystem is btrfs..."

    if ! findmnt -n -o FSTYPE / | grep -q "btrfs"; then
        print_error "Root filesystem is not btrfs!"
        print_error "This script requires a btrfs root filesystem"
        exit 1
    fi

    print_success "Btrfs filesystem detected"
}

check_grub() {
    print_info "Checking if GRUB is installed..."

    if ! command -v grub-mkconfig &> /dev/null; then
        print_error "GRUB is not installed!"
        print_error "This script requires GRUB bootloader"
        exit 1
    fi

    print_success "GRUB bootloader detected"
}

install_packages() {
    print_step "Installing snapshot packages"
    pacman -S --needed --noconfirm snapper snap-pac grub-btrfs inotify-tools btrfs-assistant
    print_success "All packages installed"
}


detect_root_subvolume() {
    print_info "Detecting root subvolume..."

    local subvol_path=$(findmnt -n -o OPTIONS / | grep -oP 'subvol=\K[^,]+' || echo "/")

    if [[ -z "$subvol_path" || "$subvol_path" == "/" ]]; then
        subvol_path=$(btrfs subvolume show / 2>/dev/null | head -n1 | awk '{print $1}' || echo "@")
    fi

    print_info "Detected root subvolume: $subvol_path"
    echo "$subvol_path"
}

create_snapper_config() {
    print_step "Configuring snapper for root filesystem"

    ROOT_SUBVOL=$(detect_root_subvolume)

    print_info "Creating snapper configuration for root..."

    if [[ -d "/.snapshots" ]]; then
        print_warning "/.snapshots directory already exists"
        print_info "Removing existing .snapshots directory..."

        if mountpoint -q "/.snapshots"; then
            umount /.snapshots
        fi

        rm -rf /.snapshots
    fi

    snapper -c root create-config /

    print_success "Snapper configuration created"

    print_info "Reconfiguring .snapshots directory..."

    btrfs subvolume delete /.snapshots
    mkdir /.snapshots

    print_success ".snapshots directory prepared"
}

setup_snapshots_mount() {
    print_step "Setting up .snapshots subvolume mount"

    ROOT_DEVICE=$(findmnt -n -o SOURCE /)

    print_info "Root device: $ROOT_DEVICE"

    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
    print_info "Root UUID: $ROOT_UUID"

    if grep -q "/.snapshots" /etc/fstab; then
        print_warning "/.snapshots entry already exists in /etc/fstab"
    else
        print_info "Adding .snapshots to /etc/fstab..."

        echo "UUID=$ROOT_UUID /.snapshots btrfs subvol=@snapshots,compress=zstd,noatime 0 0" >> /etc/fstab

        print_success "Added .snapshots to /etc/fstab"
    fi

    print_info "Creating @snapshots subvolume..."

    TEMP_MOUNT=$(mktemp -d)
    mount "$ROOT_DEVICE" "$TEMP_MOUNT"

    if [[ ! -d "$TEMP_MOUNT/@snapshots" ]]; then
        btrfs subvolume create "$TEMP_MOUNT/@snapshots"
        print_success "@snapshots subvolume created"
    else
        print_warning "@snapshots subvolume already exists"
    fi

    umount "$TEMP_MOUNT"
    rmdir "$TEMP_MOUNT"

    print_info "Mounting .snapshots..."
    mount /.snapshots

    print_success ".snapshots mounted successfully"
}

configure_snapper_limits() {
    print_step "Configuring snapper snapshot limits"

    CONFIG_FILE="/etc/snapper/configs/root"

    print_info "Setting snapshot limits to 10..."

    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

    sed -i 's/^TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="1800"/' "$CONFIG_FILE"
    sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="0"/' "$CONFIG_FILE"
    sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' "$CONFIG_FILE"
    sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' "$CONFIG_FILE"
    sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' "$CONFIG_FILE"
    sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' "$CONFIG_FILE"

    sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' "$CONFIG_FILE"
    sed -i 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="10"/' "$CONFIG_FILE"

    print_success "Snapshot limits configured:"
    print_info "  - Maximum snapshots: 10"
    print_info "  - Daily snapshots: 7"
    print_info "  - Hourly/Weekly/Monthly/Yearly: Disabled"
}

setup_grub_btrfs() {
    print_step "Configuring grub-btrfs"

    print_info "Enabling grub-btrfs service for automatic GRUB updates..."

    systemctl enable --now grub-btrfsd.service

    print_success "grub-btrfsd service enabled and started"

    print_info "Updating GRUB configuration..."
    grub-mkconfig -o /boot/grub/grub.cfg

    print_success "GRUB configuration updated with snapshot entries"
}

enable_snapper_timeline() {
    print_step "Enabling snapper automatic timeline"

    print_info "Enabling snapper timeline service..."
    systemctl enable --now snapper-timeline.timer

    print_info "Enabling snapper cleanup service..."
    systemctl enable --now snapper-cleanup.timer

    print_success "Snapper automatic snapshots enabled"
}

create_initial_snapshot() {
    print_step "Creating initial snapshot"

    print_info "Creating baseline snapshot of clean system..."
    snapper -c root create --description "Clean base system - Initial setup"

    print_success "Initial snapshot created"

    print_info "Current snapshots:"
    snapper -c root list
}

verify_snap_pac() {
    print_step "Verifying snap-pac installation"

    print_info "Checking snap-pac hooks..."

    if [[ -f /usr/share/libalpm/hooks/00-snapper-pre.hook ]] && \
       [[ -f /usr/share/libalpm/hooks/01-snapper-post.hook ]]; then
        print_success "snap-pac hooks are installed"
        print_info "Snapshots will be automatically created before and after pacman transactions"
    else
        print_warning "snap-pac hooks not found!"
    fi
}

main() {
    print_info "Starting Btrfs snapshot system setup..."
    echo ""

    check_root
    check_btrfs
    check_grub

    install_packages

    install_btrfs_assistant

    create_snapper_config

    setup_snapshots_mount

    configure_snapper_limits

    setup_grub_btrfs

    enable_snapper_timeline

    verify_snap_pac

    create_initial_snapshot

    print_success "Snapshot system setup completed successfully!"
}

main "$@"
