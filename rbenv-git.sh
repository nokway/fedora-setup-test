#!/bin/bash
#
# Development Setup
#
#   - Configure Git
#   - Generate GitHub SSH key
#   - Configure GitHub SSH
#   - Install rbenv
#   - Install ruby-build
#   - Install Ruby
#   - Configure Ruby for Bash/Zsh
#


# ============================================================
# Check sudo
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi


# ============================================================
# Variables
# ============================================================

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

RUBY_VERSION="3.4.6"

RBENV_DIR="$ACTUAL_HOME/.rbenv"
RUBY_BUILD_DIR="$RBENV_DIR/plugins/ruby-build"

SSH_DIR="$ACTUAL_HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
SSH_PUBLIC_KEY="$SSH_KEY.pub"


# ============================================================
# Colors
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
# Banner
# ============================================================

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              DEVELOPMENT SETUP                           ║"
echo "║                                                           ║"
echo "║        Git + GitHub SSH + rbenv + Ruby                    ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo "User: $ACTUAL_USER"
echo "Home: $ACTUAL_HOME"
echo ""

read -p "Press Enter to continue or CTRL+C to cancel..."


# ============================================================
# Install dependencies
# ============================================================

color_echo "yellow" "Installing development dependencies..."

dnf install -y \
    git \
    openssh-clients \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    readline-devel \
    zlib-devel \
    sqlite-devel \
    libyaml-devel \
    libffi-devel \
    bzip2 \
    bzip2-devel \
    gdbm-devel \
    ncurses-devel \
    rust \
    libxml2-devel \
    libxslt-devel

color_echo "green" "Development dependencies installed."


# ============================================================
# Git configuration
# ============================================================

color_echo "yellow" "Configuring Git..."

sudo -u "$ACTUAL_USER" \
    git config --global user.name "datorer"

sudo -u "$ACTUAL_USER" \
    git config --global \
    user.email "130174758+nokway@users.noreply.github.com"

sudo -u "$ACTUAL_USER" \
    git config --global \
    init.defaultBranch main

color_echo "green" "Git configured."


# ============================================================
# GitHub SSH
# ============================================================

color_echo "yellow" "Setting up GitHub SSH..."

mkdir -p "$SSH_DIR"

chown "$ACTUAL_USER:$ACTUAL_USER" "$SSH_DIR"
chmod 700 "$SSH_DIR"


# ------------------------------------------------------------
# Generate key
# ------------------------------------------------------------

if [ ! -f "$SSH_PUBLIC_KEY" ]; then

    color_echo "yellow" "No SSH key found. Generating one..."

    USER_EMAIL="$(
        sudo -u "$ACTUAL_USER" \
        git config --global user.email
    )"

    sudo -u "$ACTUAL_USER" \
        ssh-keygen \
        -t ed25519 \
        -f "$SSH_KEY" \
        -N "" \
        -C "$USER_EMAIL"

    color_echo "green" "SSH key generated."

else

    color_echo "green" "Existing SSH key found. Keeping it."

fi


# ------------------------------------------------------------
# Permissions
# ------------------------------------------------------------

chown "$ACTUAL_USER:$ACTUAL_USER" \
    "$SSH_KEY" \
    "$SSH_PUBLIC_KEY"

chmod 600 "$SSH_KEY"
chmod 644 "$SSH_PUBLIC_KEY"


# ------------------------------------------------------------
# GitHub SSH config
# ------------------------------------------------------------

SSH_CONFIG="$SSH_DIR/config"

if [ ! -f "$SSH_CONFIG" ]; then

    cat > "$SSH_CONFIG" <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY
    IdentitiesOnly yes
EOF

    chown "$ACTUAL_USER:$ACTUAL_USER" "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"

fi


# ------------------------------------------------------------
# Display public key
# ------------------------------------------------------------

echo ""
color_echo "green" "═══════════════════════════════════════════════════════════"
color_echo "green" "YOUR GITHUB SSH PUBLIC KEY:"
echo ""
cat "$SSH_PUBLIC_KEY"
echo ""
color_echo "green" "═══════════════════════════════════════════════════════════"
echo ""

color_echo "yellow" "Add this key to GitHub:"
echo ""
echo "GitHub → Settings → SSH and GPG keys → New SSH key"
echo ""

read -p "Press Enter after adding the key to GitHub..."


# ============================================================
# Test GitHub SSH
# ============================================================

color_echo "yellow" "Testing GitHub SSH connection..."

sudo -u "$ACTUAL_USER" \
    ssh \
    -o StrictHostKeyChecking=accept-new \
    -T git@github.com || true

echo ""


# ============================================================
# Install rbenv
# ============================================================

color_echo "yellow" "Installing rbenv..."

if [ ! -d "$RBENV_DIR" ]; then

    sudo -u "$ACTUAL_USER" \
        git clone \
        https://github.com/rbenv/rbenv.git \
        "$RBENV_DIR"

else

    color_echo "green" "rbenv already exists. Skipping clone."

fi

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$RBENV_DIR"


# ============================================================
# Configure Bash
# ============================================================

BASHRC="$ACTUAL_HOME/.bashrc"

touch "$BASHRC"

if ! grep -q 'RBENV_ROOT="$HOME/.rbenv"' "$BASHRC"; then

    cat >> "$BASHRC" <<'EOF'

# rbenv
export RBENV_ROOT="$HOME/.rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"

if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - bash)"
fi
EOF

fi


# ============================================================
# Configure Zsh
# ============================================================

ZSHRC="$ACTUAL_HOME/.zshrc"

touch "$ZSHRC"

if ! grep -q 'RBENV_ROOT="$HOME/.rbenv"' "$ZSHRC"; then

    cat >> "$ZSHRC" <<'EOF'

# rbenv
export RBENV_ROOT="$HOME/.rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"

if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi
EOF

fi

chown "$ACTUAL_USER:$ACTUAL_USER" "$BASHRC" "$ZSHRC"


# ============================================================
# ruby-build
# ============================================================

color_echo "yellow" "Installing ruby-build..."

sudo -u "$ACTUAL_USER" \
    mkdir -p "$RBENV_DIR/plugins"

if [ ! -d "$RUBY_BUILD_DIR" ]; then

    sudo -u "$ACTUAL_USER" \
        git clone \
        https://github.com/rbenv/ruby-build.git \
        "$RUBY_BUILD_DIR"

else

    color_echo "green" "ruby-build already exists. Updating..."

    sudo -u "$ACTUAL_USER" \
        git -C "$RUBY_BUILD_DIR" pull

fi

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$RBENV_DIR"


# ============================================================
# Verify rbenv
# ============================================================

color_echo "yellow" "Checking rbenv..."

RBENV_VERSION_OUTPUT=$(
    sudo -u "$ACTUAL_USER" \
    bash -lc '
        export RBENV_ROOT="$HOME/.rbenv"
        export PATH="$RBENV_ROOT/bin:$PATH"
        eval "$(rbenv init - bash)"
        rbenv --version
    '
)

echo "$RBENV_VERSION_OUTPUT"


if [[ "$RBENV_VERSION_OUTPUT" != rbenv\ * ]]; then
    color_echo "red" "rbenv installation could not be verified."
    exit 1
fi

color_echo "green" "rbenv is working."


# ============================================================
# Install Ruby
# ============================================================

color_echo "yellow" "Installing Ruby $RUBY_VERSION..."
color_echo "blue" "This may take 10-15 minutes."


if sudo -u "$ACTUAL_USER" \
    bash -lc "
        export RBENV_ROOT=\"\$HOME/.rbenv\"
        export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
        eval \"\$(rbenv init - bash)\"
        rbenv versions --bare | grep -qx '$RUBY_VERSION'
    "
then

    color_echo "green" "Ruby $RUBY_VERSION is already installed."

else

    if ! sudo -u "$ACTUAL_USER" \
        bash -lc "
            export RBENV_ROOT=\"\$HOME/.rbenv\"
            export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
            eval \"\$(rbenv init - bash)\"
            rbenv install '$RUBY_VERSION' --verbose
        "
    then

        color_echo "yellow" \
            "Ruby definition not found. Updating ruby-build..."

        sudo -u "$ACTUAL_USER" \
            git -C "$RUBY_BUILD_DIR" pull

        color_echo "yellow" \
            "Retrying Ruby $RUBY_VERSION installation..."

        sudo -u "$ACTUAL_USER" \
            bash -lc "
                export RBENV_ROOT=\"\$HOME/.rbenv\"
                export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
                eval \"\$(rbenv init - bash)\"
                rbenv install '$RUBY_VERSION' --verbose
            "

    fi

fi


# ============================================================
# Set Ruby global version
# ============================================================

color_echo "yellow" "Setting Ruby $RUBY_VERSION as the default..."

sudo -u "$ACTUAL_USER" \
    bash -lc "
        export RBENV_ROOT=\"\$HOME/.rbenv\"
        export PATH=\"\$RBENV_ROOT/bin:\$PATH\"
        eval \"\$(rbenv init - bash)\"
        rbenv global '$RUBY_VERSION'
        rbenv rehash
    "


# ============================================================
# Verify Ruby
# ============================================================

color_echo "yellow" "Checking Ruby..."

RUBY_VERSION_OUTPUT=$(
    sudo -u "$ACTUAL_USER" \
    bash -lc '
        export RBENV_ROOT="$HOME/.rbenv"
        export PATH="$RBENV_ROOT/bin:$PATH"
        eval "$(rbenv init - bash)"
        ruby -v
    '
)

echo "$RUBY_VERSION_OUTPUT"


if [[ "$RUBY_VERSION_OUTPUT" == ruby\ "$RUBY_VERSION"* ]]; then
    color_echo "green" "Ruby $RUBY_VERSION installed successfully!"
else
    color_echo "red" "Ruby installation could not be verified."
    exit 1
fi


# ============================================================
# Finish
# ============================================================

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              DEVELOPMENT SETUP COMPLETE                   ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

color_echo "green" "Git is configured."
color_echo "green" "GitHub SSH is configured."
color_echo "green" "rbenv is installed."
color_echo "green" "Ruby $RUBY_VERSION is installed."
echo ""

color_echo "yellow" "You may need to open a new terminal for rbenv changes to take effect."
echo ""

read -p "Press Enter to exit..."
