#!/bin/bash
#
# Fedora Things To Do
#
#   - Set Hostname
#   - Configure DNF
#   - Enable DNF Autoupdate
#   - Replace Fedora Flatpak Repo with Flathub
#   - Install and Enable SSH
#   - Update Firmware
#   - RPM Fusion Repositories
#   - Multimedia Codecs
#   - AMD Codecs
#   - btop
#   - rsync
#   - tmux
#   - fastfetch
#   - git
#   - wget
#   - curl
#   - syncthing
#   - Visual Studio Code
#   - Zsh and Oh My Zsh
#   - Steam
#   - Lutris


# ============================================================
# Check that the script is run with sudo
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi


# ============================================================
# Functions
# ============================================================

color_echo() {
    local color="$1"
    local text="$2"

    case "$color" in
        "red")     echo -e "\033[0;31m$text\033[0m" ;;
        "green")   echo -e "\033[0;32m$text\033[0m" ;;
        "yellow")  echo -e "\033[1;33m$text\033[0m" ;;
        "blue")    echo -e "\033[0;34m$text\033[0m" ;;
        *)         echo "$text" ;;
    esac
}


# ============================================================
# Variables
# ============================================================

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

LOG_FILE="/var/log/fedora_things_to_do.log"


# ============================================================
# Logging
# ============================================================

get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}


# ============================================================
# Error tracking
# ============================================================

FAILURES=0

log_message "=== NATTD run started ==="

trap '
    exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        FAILURES=$((FAILURES+1))
        log_message "FAILED command (exit $exit_code) at line $LINENO"
    fi
' ERR


# ============================================================
# Reboot prompt
# ============================================================

prompt_reboot() {
    read -p "It is time to reboot the machine. Would you like to do it now? (y/n): " choice

    if [[ "$choice" == [yY] ]]; then
        color_echo "green" "Rebooting..."
        reboot
    else
        color_echo "red" "Reboot canceled."
    fi
}


# ============================================================
# Backup configuration files
# ============================================================

backup_file() {
    local file="$1"

    if [ -f "$file" ]; then
        cp "$file" "$file.bak"

        if [ $? -eq 0 ]; then
            color_echo "green" "Backed up $file"
        else
            color_echo "red" "Failed to backup $file"
        fi
    fi
}


# ============================================================
# Banner
# ============================================================

echo ""
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║   ░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░░░█░█░█▀█░█▀▄░█░█░█▀▀░▀█▀░█▀█░▀█▀░▀█▀░█▀█░█▀█░   ║"
echo "║   ░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░░░█▄█░█░█░█▀▄░█▀▄░▀▀█░░█░░█▀█░░█░░░█░░█░█░█░█░   ║"
echo "║   ░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀░▀░░▀░░▀▀▀░▀▀▀░▀░▀░   ║"
echo "║   ░░░░░░░░░░░░▀█▀░█░█░▀█▀░█▀█░█▀▀░█▀▀░░░▀█▀░█▀█░░░█▀▄░█▀█░█░░░░░░░░░░░░░░   ║"
echo "║   ░░░░░░░░░░░░░█░░█▀█░░█░░█░█░█░█░▀▀█░░░░█░░█░█░░░█░█░█░█░▀░░░░░░░░░░░░░░   ║"
echo "║   ░░░░░░░░░░░░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀░░▀▀▀░▀░░░░░░░░░░░░░░   ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "This script automates \"Things To Do!\" steps after a fresh Fedora Workstation installation."
echo ""
echo "Running as user: $ACTUAL_USER"
echo "Home directory:  $ACTUAL_HOME"
echo ""
echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""

read -p "Press Enter to continue or CTRL+C to cancel..."


# ============================================================
# System Upgrade
# ============================================================

color_echo "blue" "Performing system upgrade... This may take a while..."

dnf upgrade -y


# ============================================================
# System Configuration
# ============================================================

color_echo "yellow" "Setting hostname..."

hostnamectl set-hostname datorer


# ============================================================
# Configure DNF
# ============================================================

color_echo "yellow" "Configuring DNF Package Manager..."

backup_file "/etc/dnf/dnf.conf"

dnf -y install dnf-plugins-core

if ! grep -q "^max_parallel_downloads=" /etc/dnf/dnf.conf; then
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
fi

if ! grep -q "^fastestmirror=" /etc/dnf/dnf.conf; then
    echo "fastestmirror=True" >> /etc/dnf/dnf.conf
fi

if ! grep -q "^defaultyes=" /etc/dnf/dnf.conf; then
    echo "defaultyes=True" >> /etc/dnf/dnf.conf
fi


# ============================================================
# DNF Automatic
# ============================================================

color_echo "yellow" "Enabling DNF autoupdate..."

dnf install -y dnf-automatic

sed -i 's/apply_updates = no/apply_updates = yes/' \
    /etc/dnf/automatic.conf

systemctl enable --now dnf-automatic.timer


# ============================================================
# Flatpak / Flathub
# ============================================================

color_echo "yellow" "Replacing Fedora Flatpak Repo with Flathub..."

dnf install -y flatpak

flatpak remote-delete fedora --force || true

flatpak remote-add \
    --if-not-exists \
    flathub \
    https://flathub.org/repo/flathub.flatpakrepo

flatpak repair
flatpak update -y


# ============================================================
# SSH Server
# ============================================================

color_echo "yellow" "Installing and enabling SSH..."

dnf install -y openssh-server openssh-clients

systemctl enable --now sshd


# ============================================================
# Firmware
# ============================================================

color_echo "yellow" "Checking for firmware updates..."

fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y


# ============================================================
# RPM Fusion
# ============================================================

color_echo "yellow" "Enabling RPM Fusion repositories..."

dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"

dnf install -y \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

dnf group install core -y


# ============================================================
# Multimedia Codecs
# ============================================================

color_echo "yellow" "Installing multimedia codecs..."

dnf swap ffmpeg-free ffmpeg --allowerasing -y

dnf group install multimedia \
    --setopt="install_weak_deps=False" \
    --exclude=PackageKit-gstreamer-plugin \
    -y

dnf group install sound-and-video -y


# ============================================================
# AMD Codecs
# ============================================================

color_echo "yellow" "Installing AMD Hardware Accelerated Codecs..."

color_echo "blue" \
"Note: on some AMD GPUs the freeworld VA-API drivers can cause a performance regression in games."

dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y


# ============================================================
# Essential Applications
# ============================================================

color_echo "yellow" "Installing essential applications..."

dnf install -y \
    btop \
    rsync \
    tmux \
    fastfetch \
    git \
    wget \
    curl \
    syncthing

color_echo "green" "Essential applications installed successfully."


# ============================================================
# Visual Studio Code
# ============================================================

color_echo "yellow" "Installing Visual Studio Code..."

rpm --import https://packages.microsoft.com/keys/microsoft.asc

cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf install -y code

color_echo "green" "Visual Studio Code installed successfully."


# ============================================================
# Zsh and Oh My Zsh
# ============================================================

color_echo "yellow" "Installing Zsh and Oh My Zsh..."

dnf install -y zsh

sudo -u "$ACTUAL_USER" \
    sh -c 'RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'


ZSH_CUSTOM="$ACTUAL_HOME/.oh-my-zsh/custom"

sudo -u "$ACTUAL_USER" \
    git clone \
    https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
    2>/dev/null || true

sudo -u "$ACTUAL_USER" \
    git clone \
    https://github.com/marlonrichert/zsh-autocomplete.git \
    "$ZSH_CUSTOM/plugins/zsh-autocomplete" \
    2>/dev/null || true

sudo -u "$ACTUAL_USER" \
    git clone \
    https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search" \
    2>/dev/null || true

sudo -u "$ACTUAL_USER" \
    git clone \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
    2>/dev/null || true


ZSHRC="$ACTUAL_HOME/.zshrc"

if [ -f "$ZSHRC" ]; then

    sed -i \
        's/^plugins=.*/plugins=(dnf aliases genpass git zsh-autosuggestions zsh-autocomplete zsh-history-substring-search z zsh-syntax-highlighting)/' \
        "$ZSHRC"

    sed -i \
        's/^ZSH_THEME=.*/ZSH_THEME="jonathan"/' \
        "$ZSHRC"

    chown "$ACTUAL_USER:$ACTUAL_USER" "$ZSHRC"

fi

chsh -s "$(command -v zsh)" "$ACTUAL_USER"

color_echo "green" "Zsh and Oh My Zsh installed successfully."


# ============================================================
# Steam
# ============================================================

color_echo "yellow" "Installing Steam..."

dnf install -y steam

color_echo "green" "Steam installed successfully."


# ============================================================
# Lutris
# ============================================================

color_echo "yellow" "Installing Lutris..."

dnf install -y lutris

color_echo "green" "Lutris installed successfully."


# ============================================================
# Finish
# ============================================================

cd /tmp || cd "$ACTUAL_HOME" || cd /

log_message "=== NATTD run finished with $FAILURES failed command(s) ==="

if [ "$FAILURES" -eq 0 ]; then
    color_echo "green" "All steps completed successfully. Enjoy!"
else
    color_echo "yellow" \
        "All steps attempted, but $FAILURES command(s) reported an error."

    color_echo "yellow" \
        "Check $LOG_FILE for details."
fi


echo ""
echo "╔═════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                         ║"
echo "║   ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█░░░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░█░   ║"
echo "║   ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█░░░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░▀░   ║"
echo "║   ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀░░░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀░   ║"
echo "║                                                                         ║"
echo "╚═════════════════════════════════════════════════════════════════════════╝"
echo ""

prompt_reboot
