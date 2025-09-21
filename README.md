# 🚀 Arch Linux Hyprland Dotfiles

A simple but functional arch linux setup with hyprland.

<img width="1921" height="1081" alt="image" src="https://github.com/user-attachments/assets/6025d87e-b026-47f0-98eb-c110066ca396" />
<img width="1921" height="1081" alt="image" src="https://github.com/user-attachments/assets/796b7ec1-a4e2-40d6-a5cc-c7c41d400234" />
<img width="1921" height="1080" alt="image" src="https://github.com/user-attachments/assets/37eb0ba0-c230-4c5e-a277-c0f63aed68a0" />


## ✨ Default apps

- **🪟 Window Manager**: Hyprland
- **🎨 Theme**: Inspired on rosé pine colorscheme
- **📊 Status Bar**: Waybar
- **🚀 Terminal**: Kitty
- **🔍 Application Launcher**: Rofi
- **📝 Editor**: Neovim
- **🔔 Notifications**: SwayNC
- **🖼️ Wallpapers**: Hyprpaper
- **🔒 Screen Locking**: Hyprlock
- **📸 Screenshots**: Hyprshot
- **🎯 Shell**: Bash with starship
- **📋 Clipboard**: Cliphist for clipboard history
- **💻 Terminal Multiplexer**: Tmux

### Core Desktop Environment
- **Display Manager**: SDDM
- **Session Manager**: UWSM (Universal Wayland Session Manager)
- **Audio**: PipeWire + WirePlumber
- **File Manager**: Nemo with thumbnails support
- **Theming**: GTK/Qt theming tools (nwg-look, qt5ct, qt6ct)

### Productivity
- LibreOffice Fresh
- Document viewer (Atril)
- Image viewer (Eye of GNOME)
- Media player (MPV)
- Calculator (GNOME Calculator)

## 📋 Requirements

- **OS**: Arch Linux (or Arch-based distribution)
- **Architecture**: x86_64
- **Internet Connection**: Required for package installation
- **User Account**: Non-root user with sudo privileges

## ⚡ Quick Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ImToad06/dotfiles.git
   cd dotfiles
   ```

2. **Run the installation script**:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Follow the interactive prompts** for optional features:
   - Bluetooth support
   - Printing support
   - Auto-cpufreq for laptops

4. **Reboot and enjoy**:
   ```bash
   sudo reboot
   ```

## 🖼️ Wallpapers and Icons Setup

**Important**: This repository does **NOT** include wallpapers or icons. You must provide your own.

### Required Directory Structure

The configuration files expect the following directory structure in your home folder:

```
~/Pictures/
├── wallpapers/          # Place your wallpaper images here
└── icons/               # Place your icon images here
```

### Configuration Files Affected

The following configuration files reference these paths:

- **`hyprpaper.conf`** - Looks for wallpapers in `~/Pictures/wallpapers/`
- **`hyprlock.conf`** - Looks for wallpapers and icons in `~/Pictures/wallpapers/` and `~/Pictures/icons/`

### Setup Steps

1. **Create the directories**:
   ```bash
   mkdir -p ~/Pictures/{wallpapers,icons}
   ```

2. **Add your images**:
   - Copy your wallpaper images to `~/Pictures/wallpapers/`
   - Copy any custom icons to `~/Pictures/icons/`

3. **Update configuration files**:
   - Edit `~/.config/hypr/hyprpaper.conf` to reference your specific wallpaper files
   - Edit `~/.config/hypr/hyprlock.conf` to reference your wallpaper and icon files
   - Update file names and paths to match your images

### Example Configuration

**hyprpaper.conf**:
```bash
preload = ~/Pictures/wallpapers/your-wpaper.jpg
wallpaper = ,~/Pictures/wallpapers/your-wpaperr.jpg
```

**hyprlock.conf**:
```bash
background {
  monitor =
  path = ~/Pictures/wallpapers/your-wpaper.jpg
  blur_passes = 0
  color = rgb(1e1e2e)
}
image {
  monitor =
  path = ~/Pictures/icons/your-icon.jpg
  size = 100
  border_color = $accent
  position = 0, 75
  halign = center
  valign = center
}
```

## 🛠️ Manual Installation

If you prefer to install manually or want to understand what the script does:

### 1. Install Base Packages

```bash
sudo pacman -S sddm uwsm hyprland kitty swaync pipewire wireplumber \
xdg-desktop-portal-hyprland hyprpolkitagent qt5-wayland qt6-wayland \
noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk \
ttf-cascadia-code-nerd ttf-liberation waybar hyprpaper hypridle \
hyprlock hyprshot rofi-wayland wl-clipboard cliphist xdg-user-dirs \
nemo ffmpegthumbnailer network-manager-applet base-devel wget curl \
git tar zip unzip ripgrep fd fzf stow tmux starship neovim fastfetch \
libreoffice-fresh atril eog mpv pavucontrol gnome-calculator timeshift \
cronie xorg-xhost grub-btrfs adw-gtk-theme papirus-icon-theme \
adwaita-cursors nwg-look qt5ct qt6ct rofimoji
```

### 2. Enable Services

```bash
# System services
sudo systemctl enable sddm.service

# User services
systemctl --user enable swaync.service waybar.service hypridle.service \
hyprpolkitagent.service hyprpaper.service
```

### 3. Setup User Directories

```bash
xdg-user-dirs-update
```

### 4. Configure Default Terminal

```bash
gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'
```

### 5. Install Dotfiles

```bash
# Remove existing configs
rm -rf ~/.bashrc ~/.config/{fastfetch,hypr,kitty,nvim,rofi,starship.toml,swaync,tmux,tmux-sessionizer,uwsm,waybar}

# Stow packages
stow bash fastfetch hyprland kitty nvim rofi scripts starship swaync tmux tmux-sessionizer uwsm waybar
```

## 🔧 Optional Components

### Bluetooth Support
```bash
sudo pacman -S bluetooth bluetooth-utils bluez blueman
sudo systemctl enable --now bluetooth.service
```

### Printing Support
```bash
sudo pacman -S cups cups-pdf gutenprint foomatic-db-gutenprint-ppds
sudo systemctl enable --now cups.service
```

### AUR Helper (Paru)
```bash
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si
```

### Battery Optimization (Laptops)
```bash
paru -S auto-cpufreq
sudo systemctl enable --now auto-cpufreq.service
```

## 🎨 Customization

### Themes
- **GTK Theme**: Adw-gtk-theme (dark)
- **Icon Theme**: Papirus
- **Cursor Theme**: Adwaita
- **Font**: Cascadia Code Nerd Font

## ⭐ Show Your Support

If you found this helpful, please consider giving it a star! ⭐
----
