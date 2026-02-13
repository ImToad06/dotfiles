#!/bin/bash

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOGFILE="/var/log/arch-printing-setup.log"

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

    print_info "Setting up printing/scanning for user: $REAL_USER"
}

install_printing_packages() {
    print_step "Installing CUPS and printing packages"

    print_info "Installing core printing packages..."

    PACKAGES=(
        cups
        cups-pdf
        gutenprint
        foomatic-db-engine
        foomatic-db
        foomatic-db-ppds
        foomatic-db-nonfree
        foomatic-db-nonfree-ppds
        ghostscript
        gsfonts
        system-config-printer
    )
    pacman -S --needed --noconfirm "${PACKAGES[@]}"
    print_success "Printing packages installed"
}

install_scanning_packages() {
    print_step "Installing scanning packages"

    print_info "Installing SANE and scanning tools..."

    PACKAGES=(
        sane
        sane-airscan
        simple-scan
        xsane
        ipp-usb
    )
    pacman -S --needed --noconfirm "${PACKAGES[@]}"
    print_success "Scanning packages installed"
}

enable_cups_service() {
    print_step "Enabling CUPS printing service"

    print_info "Enabling cups.service..."
    systemctl enable cups.service

    print_info "Starting cups.service..."
    systemctl start cups.service

    print_success "CUPS service is running"
}

add_user_to_groups() {
    print_step "Adding user to printing/scanning groups"

    print_info "Adding $REAL_USER to 'lp' group (printing)..."
    usermod -aG lp "$REAL_USER"

    print_info "Adding $REAL_USER to 'scanner' group (scanning)..."

    if ! getent group scanner > /dev/null; then
        groupadd scanner
        print_info "Created 'scanner' group"
    fi
    usermod -aG scanner "$REAL_USER"

    print_info "Adding $REAL_USER to 'sys' group (USB device access)..."
    usermod -aG sys "$REAL_USER"

    print_success "User added to printing/scanning groups"
    print_warning "User will need to log out and back in for group changes to take effect"
}

configure_cups_pdf() {
    print_step "Configuring cups-pdf virtual printer"

    CONFIG_FILE="/etc/cups/cups-pdf.conf"
    if [[ -f "$CONFIG_FILE" ]]; then
        print_info "Configuring cups-pdf output directory..."
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
        sed -i "s|^Out .*|Out \${HOME}/PDF|" "$CONFIG_FILE"
        sed -i "s|^#UserUMask .*|UserUMask 0033|" "$CONFIG_FILE"
        print_success "cups-pdf configured to save PDFs to ~/PDF"
    else
        print_warning "cups-pdf config file not found at $CONFIG_FILE"
    fi

    PDF_DIR="/home/$REAL_USER/PDF"
    if [[ ! -d "$PDF_DIR" ]]; then
        mkdir -p "$PDF_DIR"
        chown "$REAL_USER:$REAL_USER" "$PDF_DIR"
        print_info "Created PDF output directory: $PDF_DIR"
    fi
}

enable_avahi() {
    print_step "Enabling network printer discovery (Avahi)"

    print_info "Installing Avahi..."
    pacman -S --needed --noconfirm avahi nss-mdns

    print_info "Configuring NSS for mDNS resolution..."

    cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

    if ! grep -q "mdns_minimal" /etc/nsswitch.conf; then
        sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf
        print_info "Updated /etc/nsswitch.conf for mDNS"
    fi

    print_info "Enabling avahi-daemon.service..."
    systemctl enable avahi-daemon.service
    systemctl start avahi-daemon.service

    print_success "Avahi enabled for network printer/scanner discovery"
}

enable_ipp_usb() {
    print_step "Enabling IPP-over-USB for driverless printing"

    print_info "Enabling ipp-usb.service..."
    systemctl enable ipp-usb.service
    systemctl start ipp-usb.service

    print_success "IPP-over-USB enabled (supports driverless USB printers/scanners)"
}

configure_firewall() {
    print_step "Configuring firewall for network printing"

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        print_info "UFW firewall detected and active"
        print_info "Opening ports for CUPS and Avahi..."

        ufw allow 631/tcp comment "CUPS printing"

        ufw allow 5353/udp comment "Avahi mDNS"

        print_success "Firewall rules added for printing services"
    else
        print_info "UFW not active, skipping firewall configuration"
    fi
}

test_printer_detection() {
    print_step "Testing printer detection"

    print_info "Searching for available printers..."
    print_info "This may take a moment..."

    if lpinfo -v &> /dev/null; then
        print_success "Printer detection working"
        print_info "Available printer devices:"
        lpinfo -v | head -n 10 || true
    else
        print_warning "Could not detect printers (this is normal if no printers are connected)"
    fi
}

test_scanner_detection() {
    print_step "Testing scanner detection"

    print_info "Searching for available scanners..."
    print_info "This may take a moment..."

    if scanimage -L &> /dev/null; then
        print_success "Scanner detection working"
        scanimage -L || true
    else
        print_warning "Could not detect scanners (this is normal if no scanners are connected)"
    fi
}

main() {
    print_info "Starting printing & scanning setup..."
    echo ""

    check_root

    get_real_user

    install_printing_packages

    install_scanning_packages

    enable_cups_service

    add_user_to_groups

    configure_cups_pdf

    enable_avahi

    enable_ipp_usb

    configure_firewall

    test_printer_detection

    test_scanner_detection

    display_summary

    print_success "Printing & scanning setup completed successfully!"
}

main "$@"
