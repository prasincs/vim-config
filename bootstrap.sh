#!/bin/bash

# Bootstrap script for portable Neovim setup with Zig, Rust, Go, and Python support
# Clones vim-config to ~/vim-config and symlinks ~/.config/nvim -> ~/vim-config
# Usage: curl -sSL https://raw.githubusercontent.com/[username]/vim-config/master/bootstrap.sh | bash

set -e

echo "🚀 Setting up Neovim with Zig, Rust, Go, and Python support..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/fedora-release ]; then
            echo "fedora"
        elif [ -f /etc/arch-release ]; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Install Neovim if not present
if ! command_exists nvim; then
    echo "📦 Installing Neovim..."

    case $OS in
        debian)
            # Try to get latest version from GitHub releases
            echo "Downloading Neovim AppImage..."
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage

            # Extract if FUSE is not available (common in containers)
            if ! ./nvim.appimage --version >/dev/null 2>&1; then
                echo "Extracting AppImage (no FUSE support)..."
                ./nvim.appimage --appimage-extract
                sudo mv squashfs-root /opt/nvim
                sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim
                rm nvim.appimage
            else
                sudo mv nvim.appimage /usr/local/bin/nvim
            fi
            ;;
        fedora)
            sudo dnf install -y neovim
            ;;
        arch)
            sudo pacman -S --noconfirm neovim
            ;;
        macos)
            if command_exists brew; then
                brew install neovim
            else
                echo "Please install Homebrew first: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            echo "⚠️  Please install Neovim manually for your system"
            echo "Visit: https://github.com/neovim/neovim/releases"
            exit 1
            ;;
    esac
fi

# Install git if not present
if ! command_exists git; then
    echo "📦 Installing git..."
    case $OS in
        debian)
            sudo apt-get update && sudo apt-get install -y git
            ;;
        fedora)
            sudo dnf install -y git
            ;;
        arch)
            sudo pacman -S --noconfirm git
            ;;
        macos)
            brew install git
            ;;
    esac
fi

# Install build essentials for native modules
echo "📦 Installing build tools..."
case $OS in
    debian)
        sudo apt-get update && sudo apt-get install -y build-essential curl
        ;;
    fedora)
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y gcc-c++
        ;;
    arch)
        sudo pacman -S --noconfirm base-devel
        ;;
    macos)
        xcode-select --install 2>/dev/null || true
        ;;
esac

# Install wl-clipboard for Wayland/Crostini clipboard support
if [[ "$XDG_SESSION_TYPE" == "wayland" ]] || [[ -n "$SOMMELIER_VERSION" ]]; then
    echo "📋 Installing Wayland clipboard support..."
    case $OS in
        debian)
            sudo apt-get install -y wl-clipboard
            ;;
        fedora)
            sudo dnf install -y wl-clipboard
            ;;
        arch)
            sudo pacman -S --noconfirm wl-clipboard
            ;;
    esac
fi

# Clone or update the configuration in ~/vim-config
if [ -d "$HOME/vim-config/.git" ]; then
    echo "📂 vim-config already exists - preserving local configuration"
    echo "   To update from remote, manually run: git -C ~/vim-config pull"
elif [ -d "$HOME/vim-config" ]; then
    # Directory exists but not a git repo - leave it alone
    echo "📂 vim-config directory exists (not a git repo) - preserving local configuration"
else
    echo "📥 Cloning vim-config repository..."
    git clone -b ${GITHUB_BRANCH:-master} https://github.com/${GITHUB_USER:-prasincs}/vim-config.git "$HOME/vim-config"
fi

# Symlink ~/.config/nvim to ~/vim-config (only if vim-config exists)
mkdir -p "$HOME/.config"
if [ -d "$HOME/vim-config" ]; then
    if [ -L "$HOME/.config/nvim" ]; then
        # Already a symlink - check if it points to the right place
        CURRENT_TARGET=$(readlink "$HOME/.config/nvim")
        if [ "$CURRENT_TARGET" != "$HOME/vim-config" ]; then
            echo "⚠️  ~/.config/nvim symlink points to: $CURRENT_TARGET"
            echo "   Expected: $HOME/vim-config"
            echo "   To fix, run: ln -sf ~/vim-config ~/.config/nvim"
        else
            echo "✅ Symlink already correct: ~/.config/nvim -> ~/vim-config"
        fi
    elif [ -d "$HOME/.config/nvim" ]; then
        # Existing directory - don't touch it, warn user
        echo "⚠️  ~/.config/nvim is a directory (not symlink to vim-config)"
        echo "   Bootstrap will NOT modify existing nvim configuration."
        echo "   To use vim-config, manually run:"
        echo "     mv ~/.config/nvim ~/.config/nvim.backup"
        echo "     ln -s ~/vim-config ~/.config/nvim"
    elif [ ! -e "$HOME/.config/nvim" ]; then
        # No existing config - create symlink
        ln -s "$HOME/vim-config" "$HOME/.config/nvim"
        echo "✅ Created symlink: ~/.config/nvim -> ~/vim-config"
    fi
fi

# Ensure init.lua exists at the expected location (only check if vim-config exists)
if [ -d "$HOME/vim-config" ] && [ ! -f "$HOME/vim-config/init.lua" ]; then
    echo "⚠️  init.lua not found in ~/vim-config"
    echo "   Plugins and language servers may not work correctly."
fi

# First run to install plugins and language servers
echo "🔧 Installing plugins and language servers..."
echo "This may take a few minutes on first run..."

# Install lazy.nvim plugins and verify
echo "   Installing Lazy.nvim plugins..."
nvim --headless "+Lazy! sync" +qa 2>&1

# Verify lazy.nvim was installed
if [ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]; then
    echo "❌ Lazy.nvim failed to install!"
    echo "   Try running 'nvim' manually to see errors"
    exit 1
fi
echo "   ✅ Lazy.nvim plugins installed"

# Wait a moment for lazy to finish
sleep 2

# Install Mason packages (language servers)
echo "   Installing language servers via Mason..."
nvim --headless -c "MasonInstall rust-analyzer gopls" -c "sleep 30" -c "qall" 2>&1 || true

# Verify Mason packages installed
MASON_FAILED=0
if [ ! -x "$HOME/.local/share/nvim/mason/bin/rust-analyzer" ]; then
    echo "   ⚠️  rust-analyzer not installed (will retry)"
    MASON_FAILED=1
fi
if [ ! -x "$HOME/.local/share/nvim/mason/bin/gopls" ]; then
    echo "   ⚠️  gopls not installed (will retry)"
    MASON_FAILED=1
fi
# Retry Mason install if needed
if [ $MASON_FAILED -eq 1 ]; then
    echo "   Retrying Mason install..."
    nvim --headless -c "MasonInstall rust-analyzer gopls" -c "sleep 60" -c "qall" 2>&1 || true
fi

# Final verification of Mason packages
if [ -x "$HOME/.local/share/nvim/mason/bin/rust-analyzer" ]; then
    echo "   ✅ rust-analyzer installed"
else
    echo "   ⚠️  rust-analyzer not installed - run :MasonInstall rust-analyzer in nvim"
fi
if [ -x "$HOME/.local/share/nvim/mason/bin/gopls" ]; then
    echo "   ✅ gopls installed"
else
    echo "   ⚠️  gopls not installed - run :MasonInstall gopls in nvim"
fi
# Install Treesitter parsers
echo "   Installing Treesitter parsers..."
nvim --headless -c "TSInstall rust go zig lua vim vimdoc python" -c "sleep 10" -c "qall" 2>&1 || true

# Optional: Install language toolchains if desired
echo ""
echo "📦 Optional: Install language toolchains"
echo "Would you like to install Rust, Go, Zig, and Python (uv)? (y/N)"
if [ -t 0 ]; then
    read -r response
else
    # When piped (e.g., curl | bash), read from terminal directly
    read -r response </dev/tty 2>/dev/null || response=""
fi
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # Install Rust (latest stable via rustup)
    if ! command_exists rustc; then
        echo "🦀 Installing Rust (latest stable)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source "$HOME/.cargo/env"
        echo "Installed: $(rustc --version)"
    else
        echo "Rust already installed: $(rustc --version)"
        # Update to latest stable if rustup is available
        if command_exists rustup; then
            echo "Updating Rust to latest stable..."
            rustup update stable
        fi
    fi

    # Install/upgrade Go (latest stable)
    echo "🐿️ Checking Go installation..."
    GO_LATEST=$(curl -sL https://go.dev/VERSION?m=text | head -n1)
    if command_exists go; then
        GO_CURRENT=$(go version | grep -o 'go[0-9.]*' | head -1)
        echo "Current Go: $GO_CURRENT"
        echo "Latest Go:  $GO_LATEST"
        if [ "$GO_CURRENT" = "$GO_LATEST" ]; then
            echo "✅ Go is already up to date"
        else
            echo "Upgrading Go..."
            case $OS in
                linux|debian|fedora|arch)
                    GO_VERSION=$(echo "$GO_LATEST" | sed 's/go//')
                    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
                    sudo rm -rf /usr/local/go
                    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
                    rm "go${GO_VERSION}.linux-amd64.tar.gz"
                    ;;
                macos)
                    brew upgrade go 2>/dev/null || brew install go
                    ;;
            esac
            echo "✅ Upgraded: $(go version)"
        fi
    else
        echo "Installing $GO_LATEST..."
        case $OS in
            linux|debian|fedora|arch)
                GO_VERSION=$(echo "$GO_LATEST" | sed 's/go//')
                wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
                sudo rm -rf /usr/local/go
                sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
                rm "go${GO_VERSION}.linux-amd64.tar.gz"

                # Add to PATH if not already present
                if ! grep -q '/usr/local/go/bin' "$HOME/.bashrc"; then
                    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
                fi
                export PATH=$PATH:/usr/local/go/bin
                ;;
            macos)
                brew install go
                ;;
        esac
        echo "✅ Installed: $(go version)"
    fi

    # Install/upgrade Zig to latest master build
    echo "⚡ Checking Zig installation..."

    # Determine architecture key for JSON index
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ZIG_ARCH="x86_64" ;;
        aarch64|arm64) ZIG_ARCH="aarch64" ;;
        *) ZIG_ARCH="x86_64" ;;
    esac

    case $OS in
        linux|debian|fedora|arch)
            ZIG_PLATFORM="${ZIG_ARCH}-linux"
            ;;
        macos)
            ZIG_PLATFORM="${ZIG_ARCH}-macos"
            ;;
    esac

    # Get latest version info from official JSON index (master is first entry)
    ZIG_INDEX=$(curl -sL https://ziglang.org/download/index.json | tr -d '\n ')
    ZIG_JSON=$(echo "$ZIG_INDEX" | grep -o "\"${ZIG_PLATFORM}\":{[^}]*}" | head -1)
    ZIG_URL=$(echo "$ZIG_JSON" | grep -o '"tarball":"[^"]*"' | cut -d'"' -f4)
    ZIG_SHA=$(echo "$ZIG_JSON" | grep -o '"shasum":"[^"]*"' | cut -d'"' -f4)
    ZIG_LATEST=$(echo "$ZIG_INDEX" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -z "$ZIG_URL" ]; then
        echo "Could not find Zig master build, falling back to brew..."
        if [ "$OS" = "macos" ]; then
            brew install zig
        fi
    else
        # Check if upgrade is needed
        NEED_INSTALL=1
        if command_exists zig; then
            CURRENT_ZIG=$(zig version 2>/dev/null || echo "unknown")
            echo "Current Zig: $CURRENT_ZIG"
            echo "Latest Zig:  $ZIG_LATEST"
            if [ "$CURRENT_ZIG" = "$ZIG_LATEST" ]; then
                echo "✅ Zig is already up to date"
                NEED_INSTALL=0
            else
                echo "Upgrading Zig to $ZIG_LATEST..."
            fi
        else
            echo "Installing Zig $ZIG_LATEST..."
        fi

        if [ "$NEED_INSTALL" = "1" ]; then
            echo "Downloading from: $ZIG_URL"
            curl -sL "$ZIG_URL" -o zig.tar.xz

            # Verify SHA256 checksum
            echo "Verifying checksum..."
            if command_exists shasum; then
                ACTUAL_SHA=$(shasum -a 256 zig.tar.xz | cut -d' ' -f1)
            else
                ACTUAL_SHA=$(sha256sum zig.tar.xz | cut -d' ' -f1)
            fi

            if [ "$ACTUAL_SHA" != "$ZIG_SHA" ]; then
                echo "❌ Checksum verification failed!"
                echo "   Expected: $ZIG_SHA"
                echo "   Got:      $ACTUAL_SHA"
                rm zig.tar.xz
                exit 1
            fi
            echo "✅ Checksum verified"

            # Extract version from filename for directory naming
            ZIG_DIR=$(basename "$ZIG_URL" .tar.xz)

            case $OS in
                linux|debian|fedora|arch)
                    sudo rm -rf /usr/local/zig-*-linux-*
                    sudo tar -C /usr/local -xJf zig.tar.xz
                    sudo ln -sf "/usr/local/${ZIG_DIR}/zig" /usr/local/bin/zig
                    ;;
                macos)
                    rm -rf "$HOME/.local/zig"
                    mkdir -p "$HOME/.local"
                    tar -C "$HOME/.local" -xJf zig.tar.xz
                    mv "$HOME/.local/${ZIG_DIR}" "$HOME/.local/zig"

                    # Add to PATH if not already present
                    if ! grep -q '$HOME/.local/zig' "$HOME/.zshrc" 2>/dev/null; then
                        echo 'export PATH="$HOME/.local/zig:$PATH"' >> "$HOME/.zshrc"
                    fi
                    if ! grep -q '$HOME/.local/zig' "$HOME/.bashrc" 2>/dev/null; then
                        echo 'export PATH="$HOME/.local/zig:$PATH"' >> "$HOME/.bashrc"
                    fi
                    export PATH="$HOME/.local/zig:$PATH"
                    ;;
            esac

            rm zig.tar.xz
            echo "✅ Installed: $(zig version)"
        fi
    fi

    # Install/upgrade uv (Python package manager)
    echo "🐍 Checking uv installation..."

    if command_exists uv; then
        UV_CURRENT=$(uv --version 2>/dev/null | grep -o '[0-9.]*' | head -1)
        echo "Current uv: $UV_CURRENT"
        echo "Updating uv to latest..."
        uv self update 2>/dev/null || {
            # Fallback: reinstall if self update fails
            curl -LsSf https://astral.sh/uv/install.sh | sh
        }
        echo "✅ uv updated: $(uv --version)"
    else
        echo "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh

        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"

        if command_exists uv; then
            echo "✅ Installed: $(uv --version)"
        else
            echo "❌ uv installation failed"
        fi
    fi

    # Install Python and tools via uv
    if command_exists uv; then
        echo "   Installing Python 3.12..."
        uv python install 3.12 2>/dev/null || true
        echo "   ✅ Python installed"

        echo "   Installing Python tools..."
        uv tool install ipython 2>/dev/null || uv tool upgrade ipython 2>/dev/null || true
        uv tool install basedpyright 2>/dev/null || uv tool upgrade basedpyright 2>/dev/null || true
        echo "   ✅ Python tools installed"

        echo "   Installing Jupyter kernel for molten-nvim..."
        # Create a venv for neovim python support and jupyter
        NVIM_VENV="$HOME/.local/share/nvim/python-venv"
        if [ ! -d "$NVIM_VENV" ]; then
            uv venv "$NVIM_VENV"
        fi
        # Install required packages for molten-nvim
        uv pip install --python "$NVIM_VENV/bin/python" pynvim jupyter_client ipykernel cairosvg pnglatex plotly kaleido 2>/dev/null || true
        # Register the kernel
        "$NVIM_VENV/bin/python" -m ipykernel install --user --name=python3 2>/dev/null || true
        echo "   ✅ Jupyter kernel installed"
    fi
fi

echo ""
echo "🔍 Running sanity checks..."
echo ""

# Sanity check function
check_component() {
    local name="$1"
    local command="$2"
    local expected="$3"

    if eval "$command" >/dev/null 2>&1; then
        echo "✅ $name: OK"
        return 0
    else
        echo "❌ $name: FAILED"
        if [ -n "$expected" ]; then
            echo "   Expected: $expected"
        fi
        return 1
    fi
}

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check Neovim
if check_component "Neovim" "nvim --version"; then
    ((CHECKS_PASSED++))
    echo "   $(nvim --version | head -n1)"
else
    ((CHECKS_FAILED++))
fi

# Check plugins directory
if check_component "Lazy.nvim plugins" "test -d ~/.local/share/nvim/lazy/lazy.nvim"; then
    ((CHECKS_PASSED++))
    PLUGIN_COUNT=$(ls -1 ~/.local/share/nvim/lazy/ 2>/dev/null | wc -l)
    echo "   $PLUGIN_COUNT plugins installed"
else
    ((CHECKS_FAILED++))
fi

# Check Mason
if check_component "Mason" "test -d ~/.local/share/nvim/mason"; then
    ((CHECKS_PASSED++))
else
    ((CHECKS_FAILED++))
fi

# Check language servers
echo ""
echo "🔧 Checking Language Servers:"

if check_component "rust-analyzer" "test -x ~/.local/share/nvim/mason/bin/rust-analyzer"; then
    ((CHECKS_PASSED++))
    echo "   $(~/.local/share/nvim/mason/bin/rust-analyzer --version 2>&1)"
else
    ((CHECKS_FAILED++))
fi

if check_component "gopls" "test -x ~/.local/share/nvim/mason/bin/gopls"; then
    ((CHECKS_PASSED++))
    echo "   $(~/.local/share/nvim/mason/bin/gopls version 2>&1 | head -n1)"
else
    ((CHECKS_FAILED++))
    echo "   Note: gopls requires Go to be installed"
fi

# Check language toolchains if installed
echo ""
echo "🔨 Checking Language Toolchains:"

if command_exists rustc; then
    if check_component "Rust" "rustc --version"; then
        ((CHECKS_PASSED++))
        echo "   $(rustc --version)"
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ Rust: Not installed (optional)"
fi

if command_exists go; then
    if check_component "Go" "go version"; then
        ((CHECKS_PASSED++))
        echo "   $(go version)"
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ Go: Not installed (optional)"
fi

if command_exists zig; then
    if check_component "Zig" "zig version"; then
        ((CHECKS_PASSED++))
        echo "   $(zig version)"
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ Zig: Not installed (optional)"
fi

if command_exists uv; then
    if check_component "uv" "uv --version"; then
        ((CHECKS_PASSED++))
        echo "   $(uv --version)"
        # Also check Python via uv
        if uv python list 2>/dev/null | head -1 >/dev/null; then
            echo "   Python: $(uv python list 2>/dev/null | head -1)"
        fi
        # Check uv-installed tools
        if command_exists basedpyright; then
            echo "   ✅ basedpyright: $(basedpyright --version 2>&1 | head -1)"
        else
            echo "   ⚠️  basedpyright not installed (run: uv tool install basedpyright)"
        fi
        if command_exists ipython; then
            echo "   ✅ ipython installed"
        fi
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ uv: Not installed (optional)"
fi

# Check Treesitter parsers
echo ""
echo "🌳 Checking Treesitter Parsers:"
TREESITTER_DIR="$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"
if [ -d "$TREESITTER_DIR" ]; then
    for lang in rust go zig python; do
        if [ -f "$TREESITTER_DIR/${lang}.so" ]; then
            echo "✅ ${lang}.so: OK"
            ((CHECKS_PASSED++))
        else
            echo "⚠️  ${lang}.so: Not compiled yet (will compile on first use)"
        fi
    done
else
    echo "⚠️  Treesitter parser directory not found (will be created on first use)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Sanity Check Summary:"
echo "   ✅ Passed: $CHECKS_PASSED"
if [ $CHECKS_FAILED -gt 0 ]; then
    echo "   ❌ Failed: $CHECKS_FAILED"
    echo ""
    echo "⚠️  Some checks failed. Please review the output above."
    echo "   You may need to manually install missing components."
else
    echo "   ❌ Failed: 0"
    echo ""
    echo "✅ All critical checks passed!"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📝 Quick reference:"
echo "  • Leader key: <Space>"
echo "  • Build: <Space>m"
echo "  • Run: <Space>r (quickfix) or <Space>rr (terminal)"
echo "  • Test: <Space>t (quickfix) or <Space>rt (terminal)"
echo "  • Quick run current file:"
echo "    - Zig: <Space>zf"
echo "    - Rust: <Space>rf"
echo "    - Go: <Space>gf"
echo "    - Python: <Space>pf"
echo "  • Python/Jupyter: <Space>pi (init kernel), <Space>pl (eval line)"
echo "  • File explorer: <Space>e"
echo "  • Find files: <Space>ff"
echo "  • Live grep: <Space>fg"
echo "  • Writing mode: <Space>z (Zen Mode)"
echo "  • LSP hover: K"
echo "  • Go to definition: gd"
echo "  • Rename: <Space>rn"
echo "  • Code action: <Space>ca"
echo "  • Format: <Space>f"
echo ""
echo "🚀 Run 'nvim' to start coding with full Zig, Rust, Go, and Python support!"
