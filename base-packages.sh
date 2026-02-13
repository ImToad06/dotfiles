#!/bin/bash

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOGFILE="/var/log/arch-base-setup.log"

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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

backup_pacman_conf() {
    print_info "Creating backup of pacman.conf..."
    if [[ ! -f /etc/pacman.conf.backup ]]; then
        cp /etc/pacman.conf /etc/pacman.conf.backup
        print_success "Backup created: /etc/pacman.conf.backup"
    else
        print_warning "Backup already exists, skipping..."
    fi
}

update_system() {
    print_info "Updating system packages..."
    pacman -Syyu --noconfirm
    print_success "System updated successfully"
}

optimize_mirrors() {
    print_info "Optimizing pacman mirrors with reflector..."

    if ! pacman -Qi reflector &> /dev/null; then
        print_info "Installing reflector..."
        pacman -S --noconfirm reflector
    fi

    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    print_info "Mirrorlist backed up to /etc/pacman.d/mirrorlist.backup"

    print_info "Fetching fastest mirrors (this may take a moment)..."
    reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    print_success "Mirrors optimized successfully"
}

enable_parallel_downloads() {
    print_info "Enabling parallel downloads in pacman..."

    if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
        sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
        print_success "Parallel downloads enabled (10 simultaneous downloads)"
    elif grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
        print_success "Parallel downloads updated to 10"
    else
        echo "ParallelDownloads = 10" >> /etc/pacman.conf
        print_success "Parallel downloads enabled (10 simultaneous downloads)"
    fi
}

enable_pacman_color() {
    print_info "Enabling color output in pacman..."

    if grep -q "^#Color" /etc/pacman.conf; then
        sed -i 's/^#Color/Color/' /etc/pacman.conf
        print_success "Color output enabled"
    elif grep -q "^Color" /etc/pacman.conf; then
        print_warning "Color output already enabled"
    else
        sed -i '/^# Misc options/a Color' /etc/pacman.conf
        print_success "Color output enabled (added to config)"
    fi
}

enable_pacman_candy() {
    print_info "Enabling ILoveCandy easter egg in pacman..."

    if grep -q "^ILoveCandy" /etc/pacman.conf; then
        print_warning "ILoveCandy already enabled"
    else
        if grep -q "^Color" /etc/pacman.conf; then
            sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
        else
            sed -i '/^# Misc options/a ILoveCandy' /etc/pacman.conf
        fi
        print_success "ILoveCandy enabled - Pac-Man progress bar activated!"
    fi
}

install_base_packages() {
    print_info "Installing essential base packages..."

    PACKAGES=(
        # Development tools
        base-devel
        git

        # Network utilities
        curl
        wget

        # Archive utilities
        tar
        zip
        unzip
        p7zip
        unrar

        # Documentation
        man-db
        man-pages
        tealdeer

        # System monitoring
        htop
        btop

        # System utilities
        reflector
        rsync
        bash-completion
        openssh
        ufw
        less
        blueman

        # Python
        python
        python-pip

        # Filesystem
        btrfs-progs

        # Modern CLI tools
        ripgrep
        fd
        bat
        exa
        fzf

        # Terminal multiplexer
        tmux

        # Text editor
        neovim

        # Shell prompt
        starship
    )

    print_info "Packages to install: ${PACKAGES[*]}"

    pacman -S --needed --noconfirm "${PACKAGES[@]}"

    print_success "All base packages installed successfully"
}

update_tldr() {
    print_info "Updating tealdeer (tldr) database..."
    tldr --update
    print_success "Tealdeer database updated"
}

display_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    print_success "Base package installation completed!"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${BLUE}Log file:${NC} $LOGFILE"
    echo "═══════════════════════════════════════════════════════════════"
}

main() {
    print_info "Starting Arch Linux base package setup..."
    echo ""

    check_root

    backup_pacman_conf

    optimize_mirrors

    enable_parallel_downloads
    enable_pacman_color
    enable_pacman_candy

    update_system

    install_base_packages

    update_tldr

    display_summary

    print_success "Script completed successfully!"
}

# Run main function
main "$@"
