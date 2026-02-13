#!/bin/bash

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOGFILE="/var/log/paru-setup.log"

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

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root"
        print_error "AUR packages must be built as a regular user"
        print_error "Please run as your normal user (not with sudo)"
        exit 1
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."

    local missing_deps=()

    if ! pacman -Qg base-devel &> /dev/null; then
        missing_deps+=("base-devel")
    fi

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Please install them first with: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi

    print_success "All dependencies are installed"
}

check_paru_installed() {
    if command -v paru &> /dev/null; then
        print_warning "paru is already installed"
        paru --version
        read -p "Do you want to reinstall/update paru? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting without changes"
            exit 0
        fi
    fi
}

clone_paru() {
    print_info "Cloning paru repository from AUR..."

    local build_dir="$HOME/aur-builds"
    local paru_dir="$build_dir/paru"

    mkdir -p "$build_dir"

    if [[ -d "$paru_dir" ]]; then
        print_warning "Removing existing paru directory..."
        rm -rf "$paru_dir"
    fi

    cd "$build_dir"
    git clone https://aur.archlinux.org/paru.git

    print_success "paru repository cloned to $paru_dir"
    echo "$paru_dir"
}

build_install_paru() {
    local paru_dir="$1"

    print_info "Building paru from source..."
    print_info "This may take a few minutes..."

    cd "$paru_dir"

    # Build and install
    makepkg -si --noconfirm

    print_success "paru built and installed successfully"
}

cleanup_build_dir() {
    local paru_dir="$1"

    read -p "Do you want to remove the build directory ($paru_dir)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing build directory..."
        rm -rf "$paru_dir"
        print_success "Build directory removed"
    else
        print_info "Build directory kept at: $paru_dir"
    fi
}

main() {
    print_info "Starting paru AUR helper installation..."
    echo ""

    check_not_root

    check_dependencies

    check_paru_installed

    paru_dir=$(clone_paru)

    build_install_paru "$paru_dir"

    cleanup_build_dir "$paru_dir"

    print_success "Script completed successfully!"
}

main "$@"
