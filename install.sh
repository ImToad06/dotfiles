#!/bin/bash

# Arch Linux Hyprland Dotfiles Setup Script
# Author: Toad
# Description: Automated setup script for Hyprland setup

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root!"
    exit 1
fi

if ! command -v pacman &> /dev/null; then
    error "This script is designed for Arch Linux!"
    exit 1
fi

log "Starting Arch Linux Hyprland setup..."

PACKAGES=(
    sddm
    uwsm
    hyprland
    kitty
    swaync
    pipewire
    wireplumber
    xdg-desktop-portal-hyprland
    hyprpolkitagent
    qt5-wayland
    qt6-wayland
    noto-fonts
    noto-fonts-extra
    noto-fonts-emoji
    noto-fonts-cjk
    ttf-cascadia-code-nerd
    ttf-liberation
    waybar
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    rofi-wayland
    wl-clipboard
    cliphist
    xdg-user-dirs
    nemo
    ffmpegthumbnailer
    network-manager-applet
    base-devel
    wget
    curl
    git
    tar
    zip
    unzip
    ripgrep
    fd
    fzf
    nvm
    stow
    tmux
    starship
    neovim
    fastfetch
    libreoffice-fresh
    atril
    eog
    mpv
    pavucontrol
    gnome-calculator
    timeshift
    cronie
    xorg-xhost
    grub-btrfs
    adw-gtk-theme
    papirus-icon-theme
    adwaita-cursors
    nwg-look
    qt5ct
    qt6ct
    rofimoji
)

log "Updating system packages..."
sudo pacman -Syu --noconfirm

log "Installing base packages..."
for package in "${PACKAGES[@]}"; do
    log "Installing $package..."
    sudo pacman -S --noconfirm "$package" || warn "Failed to install $package, continuing..."
done

log "Enabling system services..."
sudo systemctl enable sddm.service

log "Enabling user services..."
systemctl --user enable swaync.service
systemctl --user enable waybar.service
systemctl --user enable hypridle.service
systemctl --user enable hyprpolkitagent.service
systemctl --user enable hyprpaper.service

log "Setting up user directories..."
xdg-user-dirs-update

log "Setting kitty as default terminal for nemo..."
gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'

echo
read -p "Would you like to setup Bluetooth? (y/N): " -n 1 -r bluetooth_choice
echo
if [[ $bluetooth_choice =~ ^[Yy]$ ]]; then
    log "Installing Bluetooth packages..."
    sudo pacman -S --noconfirm bluetooth bluetooth-utils bluez blueman
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    log "Bluetooth setup complete!"
fi

echo
read -p "Would you like to setup printing support? (y/N): " -n 1 -r printing_choice
echo
if [[ $printing_choice =~ ^[Yy]$ ]]; then
    log "Installing printing packages..."
    sudo pacman -S --noconfirm cups cups-pdf gutenprint foomatic-db-gutenprint-ppds
    sudo systemctl enable cups.service
    sudo systemctl start cups.service
    log "Printing setup complete!"
fi

log "Installing paru AUR helper..."
if ! command -v paru &> /dev/null; then
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd "$HOME"
    rm -rf "$temp_dir"
    log "Paru installed successfully!"
else
    log "Paru is already installed!"
fi

echo
read -p "Would you like to install auto-cpufreq for better battery life (laptops)? (y/N): " -n 1 -r cpufreq_choice
echo
if [[ $cpufreq_choice =~ ^[Yy]$ ]]; then
    log "Installing auto-cpufreq from AUR..."
    paru -S --noconfirm auto-cpufreq
    sudo systemctl enable auto-cpufreq.service
    sudo systemctl start auto-cpufreq.service
    log "Auto-cpufreq setup complete!"
fi

# Remove existing config files and directories
log "Removing existing configuration files..."
configs_to_remove=(
    "$HOME/.bashrc"
    "$HOME/.config/fastfetch"
    "$HOME/.config/hypr"
    "$HOME/.config/kitty"
    "$HOME/.config/nvim"
    "$HOME/.config/rofi"
    "$HOME/.config/starship.toml"
    "$HOME/.config/swaync"
    "$HOME/.config/tmux"
    "$HOME/.config/tmux-sessionizer"
    "$HOME/.config/uwsm"
    "$HOME/.config/waybar"
)

for config in "${configs_to_remove[@]}"; do
    if [[ -e "$config" ]]; then
        log "Removing $config..."
        rm -rf "$config"
    fi
done

log "Setting up dotfiles with stow..."
stow_packages=(
    bash
    fastfetch
    hyprland
    kitty
    nvim
    rofi
    scripts
    starship
    swaync
    tmux
    tmux-sessionizer
    uwsm
    waybar
)

if [[ ! -d "bash" ]] || [[ ! -d "hyprland" ]] || [[ ! -d "kitty" ]]; then
    warn "Stow packages not found in current directory!"
    warn "Please ensure you're running this script from your dotfiles repository root."
    warn "The following directories should be present: ${stow_packages[*]}"
    echo
    read -p "Continue anyway? (y/N): " -n 1 -r continue_choice
    echo
    if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
        error "Exiting due to missing stow packages."
        exit 1
    fi
fi

for package in "${stow_packages[@]}"; do
    if [[ -d "$package" ]]; then
        log "Stowing $package..."
        stow "$package"
    else
        warn "Stow package '$package' not found, skipping..."
    fi
done

log "Performing final setup steps..."

systemctl --user daemon-reload

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Reboot your system"
echo "2. Login through SDDM"
echo "3. Start Hyprland session"
echo "4. Your dotfiles should be active!"
echo
echo -e "${YELLOW}Notes:${NC}"
echo "- User services will start automatically on login"
echo "- Check 'systemctl --user status <service>' for any service issues"
echo "- Run 'nwg-look' to configure GTK themes"
echo "- Run 'qt5ct' and 'qt6ct' to configure Qt themes"
echo
echo -e "${GREEN}Enjoy your new Hyprland setup!${NC}"

log "Setup script completed successfully!"
