#!/bin/bash

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="/var/log/arch-full-setup.log"

print_header() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}            ARCH LINUX FULL SYSTEM SETUP${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}[STEP $1/$2]${NC} $3"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

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

get_real_user() {
    REAL_USER="${SUDO_USER:-$USER}"
    if [[ "$REAL_USER" == "root" ]]; then
        print_error "Cannot determine non-root user"
        print_error "Please run this script with sudo, not as root directly"
        exit 1
    fi
    REAL_HOME=$(eval echo "~$REAL_USER")
}

confirm_continue() {
    print_warning "This will run the following setup scripts in order:"
    echo "  1. base-packages.sh  - Base packages and pacman configuration"
    echo "  2. paru.sh           - AUR helper installation (as user)"
    echo "  3. snapper.sh        - Btrfs snapshot system"
    echo "  4. printing.sh      - CUPS printing and scanning"
    echo "  5. hyprland.sh      - Hyprland Wayland desktop"
    echo ""
    print_warning "This may take a long time and requires multiple restarts/interactions"
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted by user"
        exit 0
    fi
}

run_step() {
    local step_num=$1
    local total_steps=$2
    local step_name=$3
    local script_name=$4
    local needs_root=$5

    print_step "$step_num" "$total_steps" "$step_name"

    local script_path="$SCRIPT_DIR/$script_name"

    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        return 1
    fi

    if [[ "$needs_root" == "true" ]]; then
        if [[ $EUID -ne 0 ]]; then
            print_info "Running $script_name with sudo..."
            sudo bash "$script_path"
        else
            bash "$script_path"
        fi
    else
        if [[ $EUID -eq 0 ]]; then
            print_info "Running $script_name as user $REAL_USER..."
            sudo -u "$REAL_USER" bash "$script_path"
        else
            bash "$script_path"
        fi
    fi

    print_success "Step $step_num completed"
}

main() {
    print_header
    check_root
    get_real_user

    echo "Log file: $LOGFILE"
    echo ""

    confirm_continue

    run_step 1 5 "Base packages and pacman configuration" "base-packages.sh" "true"
    
    run_step 2 5 "AUR helper (paru) installation" "paru.sh" "false"
    
    run_step 3 5 "Btrfs snapshot system (snapper)" "snapper.sh" "true"
    
    run_step 4 5 "Printing and scanning setup" "printing.sh" "true"
    
    run_step 5 5 "Hyprland Wayland desktop" "hyprland.sh" "true"

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}            FULL SYSTEM SETUP COMPLETED!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    print_warning "Please reboot to start using your new system!"
    echo ""
}

main "$@"
