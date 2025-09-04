#!/usr/bin/env bash

# Exit if any command fails
set -e

# Colors for output
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${GREEN}==> Updating system...${RESET}"
sudo pacman -Syyu --noconfirm

PACKAGES=(
    sddm
    uwsm
    hyprland
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
    kitty
    xdg-user-dirs
    thunar
    gvfs
    thunar-archive-plugin
    file-roller
    tumbler
    ffmpegthumbnailer
    rofi-wayland
    waybar
    hyprpaper
    wl-clipboard
    cliphist
    hypridle
    hyprlock
    timeshift
    cronie
    xorg-xhost
    atril
    libreoffice-fresh
    neovim
    eog
    mpv
    gnome-calculator
    man-db
    tealdeer
    adw-gtk-theme
    papirus-icon-theme
    adwaita-cursors
    nwg-look
    qt5ct
    qt6ct
    network-manager-applet
    stow
    wget
    curl
    tar
    zip
    unzip
    fastfetch
    starship
    wpctl
    brightnessctl
)

echo -e "${GREEN}==> Installing required packages...${RESET}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo -e "${GREEN}==> Base packages installed successfully!${RESET}"

echo -e "${GREEN}==> Enabling system services...${RESET}"
sudo systemctl enable sddm.service
sudo systemctl enable cronie.service
xdg-user-dirs-update

echo -e "${GREEN}==> Enabling Hyprland user services...${RESET}"
for service in \
    hyprpolkitagent.service \
    hyprpaper.service \
    hypridle.service \
    swaync.service \
    waybar.service
do
    systemctl --user enable "$service"
done

echo -e "${GREEN}==> Setting up user Qt environment variables...${RESET}"

USER_ENV_DIR="$HOME/.config/uwsm"
USER_ENV_FILE="$USER_ENV_DIR/env"

mkdir -p "$USER_ENV_DIR"

cat > "$USER_ENV_FILE" <<'EOF'
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=qt6ct
EOF

echo -e "${GREEN}==> User environment variables written to $USER_ENV_FILE${RESET}"


echo -e "${GREEN}==> Setting up AUR helper (paru)...${RESET}"

if ! command -v paru &>/dev/null; then
    echo -e "${GREEN}==> paru not found, installing...${RESET}"
    sudo pacman -S --needed --noconfirm base-devel git

    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    cd "$tmpdir/paru"
    makepkg -si --noconfirm

    cd -
    rm -rf "$tmpdir"
else
    echo -e "${GREEN}==> paru is already installed, skipping...${RESET}"
fi

echo -e "${GREEN}==> Installing AUR packages with paru...${RESET}"

AUR_PACKAGES=(
    brave-bin
    mullvad-browser-bin
    wlogout
)

paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"

echo -e "${GREEN}==> Setting up dotfiles with stow...${RESET}"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo -e "${GREEN}==> Installing stow...${RESET}"
    sudo pacman -S --needed --noconfirm stow
fi

# Loop through subdirectories and stow each one
for dir in */; do
    # Skip if not a directory
    [ -d "$dir" ] || continue
    echo -e "${GREEN}==> Stowing $dir...${RESET}"
    stow -R --target="$HOME" "$dir"
done

echo -e "${GREEN}==> Dotfiles successfully stowed!${RESET}"
