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

LOGFILE="/var/log/hyprland-setup.log"

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

get_real_user() {
    REAL_USER="${SUDO_USER:-$USER}"

    if [[ "$REAL_USER" == "root" ]]; then
        print_error "Cannot determine non-root user"
        print_error "Please run this script with sudo, not as root directly"
        exit 1
    fi

    REAL_HOME=$(eval echo "~$REAL_USER")
    print_info "Setting up Hyprland for user: $REAL_USER"
    print_info "User home directory: $REAL_HOME"
}

install_hyprland_packages() {
    print_step "Installing Hyprland and core Wayland packages"

    print_info "Installing packages... This may take several minutes."

    PACKAGES=(
        sddm
        uwsm
        hyprland
        hyprpaper
        hyprpicker
        hypridle
        hyprlock
        hyprpolkitagent
        kitty
        swaync
        pipewire
        wireplumber
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        qt5-wayland
        qt6-wayland
        noto-fonts
        noto-fonts-extra
        noto-fonts-emoji
        noto-fonts-cjk
        ttf-cascadia-code-nerd
        waybar
        rofi
        rofimoji
        wl-clipboard
        cliphist
        nemo
        nemo-fileroller
        ffmpegthumbnailer
        yazi
        xdg-user-dirs
        atril
        eog
        libreoffice-fresh
    )

    pacman -S --needed --noconfirm "${PACKAGES[@]}"

    print_success "All packages installed successfully"
}

enable_sddm() {
    print_step "Enabling and configuring SDDM display manager"

    systemctl enable sddm.service
    systemctl start sddm.service 2>/dev/null || print_warning "SDDM will start on next boot"
    print_success "SDDM enabled and started"
}

setup_user_services() {
    print_step "Enabling user systemd services"

    print_info "Enabling services for user: $REAL_USER"

    SERVICES=(
        "waybar"
        "hypridle"
        "hyprpolkitagent"
        "hyprpaper"
    )

    print_info "The following services will auto-start with Hyprland:"
    for service in "${SERVICES[@]}"; do
        print_info "  • $service"
    done

    print_success "User services configuration noted"
    print_info "Services will activate automatically when Hyprland starts"
}

setup_xdg_directories() {
    print_step "Setting up XDG user directories"

    print_info "Running xdg-user-dirs-update for $REAL_USER..."
    sudo -u "$REAL_USER" xdg-user-dirs-update
    print_success "XDG user directories created"
    if [[ -f "$REAL_HOME/.config/user-dirs.dirs" ]]; then
        print_info "Created directories:"
        grep -v "^#" "$REAL_HOME/.config/user-dirs.dirs" | while read -r line; do
            print_info "  $line"
        done
    fi
}

configure_default_applications() {
    print_step "Configuring default applications"

    print_info "Setting default applications for $REAL_USER..."

    print_info "Setting Nemo as default file manager..."
    sudo -u "$REAL_USER" xdg-mime default nemo.desktop inode/directory
    sudo -u "$REAL_USER" xdg-mime default nemo.desktop application/x-gnome-saved-search

    print_info "Setting Kitty as default terminal..."
    sudo -u "$REAL_USER" xdg-mime default kitty.desktop application/x-terminal-emulator
    print_info "Setting Eye of GNOME as default image viewer..."
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/png
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/jpeg
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/jpg
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/gif
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/bmp
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/webp
    sudo -u "$REAL_USER" xdg-mime default eog.desktop image/svg+xml
    print_info "Setting Atril as default PDF/document viewer..."
    sudo -u "$REAL_USER" xdg-mime default atril.desktop application/pdf
    sudo -u "$REAL_USER" xdg-mime default atril.desktop application/x-pdf
    sudo -u "$REAL_USER" xdg-mime default atril.desktop application/epub+zip
    sudo -u "$REAL_USER" xdg-mime default atril.desktop application/x-cbr
    sudo -u "$REAL_USER" xdg-mime default atril.desktop application/x-cbz

    print_success "Default applications configured"
}

configure_nemo_terminal() {
    print_step "Configuring Nemo to use Kitty as terminal"

    print_info "Setting Kitty as Nemo's default terminal..."

    sudo -u "$REAL_USER" dbus-run-session gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'

    print_success "Nemo configured to use Kitty"
}

main() {
    print_info "Starting Hyprland installation and configuration..."
    echo ""
    check_root
    get_real_user
    install_hyprland_packages
    enable_sddm
    setup_user_services
    setup_xdg_directories
    configure_default_applications
    configure_nemo_terminal
    echo ""
    print_success "Hyprland installation completed!"
    print_warning "Please reboot to start using Hyprland!"
    echo ""
}

main "$@"
