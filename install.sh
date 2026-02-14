#!/bin/bash

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi

    if ! command -v pacman &> /dev/null; then
        error "This script is designed for Arch Linux"
        exit 1
    fi
}

base_packages() {
    log "Installing base packages"
    PACKAGES=(
        base-devel
        git
        curl
        wget
        tar
        zip
        unzip
        p7zip
        unrar
        man-db
        man-pages
        tealdeer
        htop
        btop
        rsync
        bash-completion
        openssh
        ufw
        less
        network-manager-applet
        blueman
        python
        python-pip
        btrfs-progs
        snap-pac
        grub-btrfs
        btrfs-assistant
        cups-pdf
        gutenprint
        ripgrep
        fd
        bat
        exa
        fzf
        tmux
        neovim
        starship
        stow
    )
    sudo pacman -Syyu --needed --noconfirm "${PACKAGES[@]}"
    log "Packages installed"
}

paru(){
    log "Installing paru as AUR helper"
    if ! command -v paru &> /dev/null; then
        temp_dir=$(mktemp -d)
        cd "$temp_dir"
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd "$HOME"
        rm -rf "$temp_dir"
        log "Paru installed successfully"
    else
        log "Paru is already installed"
    fi
}

hyprland(){
    log "Setting up hyprland"
    PACKAGES=(
        sddm
        uwsm
        hyprland
        hyprpaper
        hyprpicker
        hypridle
        hyprlock
        hyprpolkitagent
        hyprshot
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
        gnome-calculator
        fastfetch
        nwg-look
        adwaita-cursors
        papirus-icon-theme
        adw-gtk-theme
    )

    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"


    sudo systemctl enable sddm
    systemctl --user enable waybar.service
    systemctl --user enable hypridle.service
    systemctl --user enable hyprpolkitagent.service
    systemctl --user enable hyprpaper.service

    xdg-user-dirs-update

    xdg-mime default nemo.desktop inode/directory
    xdg-mime default nemo.desktop application/x-gnome-saved-search
    gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'
    xdg-mime default org.gnome.eog.desktop image/png
    xdg-mime default org.gnome.eog.desktop image/jpeg
    xdg-mime default org.gnome.eog.desktop image/jpg
    xdg-mime default org.gnome.eog.desktop image/gif
    xdg-mime default org.gnome.eog.desktop image/webp
}

stow_dotfiles() {
    rm ~/.bashrc
    rm -rf ~/.config/hypr
    stow bash fastfetch hyprland kitty nvim rofi scripts starship swaync tmux tmux-sessionizer waybar
}

main() {
    check
    base_packages
    paru
    hyprland
    stow_dotfiles
    log "Installation complete!"
}

main "$@"

