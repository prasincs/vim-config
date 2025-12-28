#!/bin/bash

# Bootstrap script for portable Neovim setup with Zig, Rust, and Go support
# Usage: curl -sSL https://raw.githubusercontent.com/[username]/vim-config/master/bootstrap.sh | bash

set -e

echo "🚀 Setting up Neovim with Zig, Rust, and Go support..."

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

# Backup existing config if present
if [ -d "$HOME/.config/nvim" ]; then
    echo "📂 Backing up existing Neovim config..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Clone the configuration
echo "📥 Cloning Neovim configuration..."
git clone -b ${GITHUB_BRANCH:-neovim-2025} https://github.com/${GITHUB_USER:-prasincs}/vim-config.git "$HOME/.config/nvim"

# Ensure init.lua exists at the expected location
if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    echo "❌ Error: init.lua not found after clone!"
    echo "   Expected: $HOME/.config/nvim/init.lua"
    exit 1
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
nvim --headless -c "TSInstall rust go zig lua vim vimdoc" -c "sleep 10" -c "qall" 2>&1 || true

# Optional: Install language toolchains if desired
echo ""
echo "📦 Optional: Install language toolchains"
echo "Would you like to install Rust, Go, and Zig? (y/N)"
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

    # Install Go (latest stable)
    if ! command_exists go; then
        echo "🐹 Installing Go (latest stable)..."
        case $OS in
            linux|debian|fedora|arch)
                # Fetch the latest stable version from the Go download page
                GO_VERSION=$(curl -sL https://go.dev/VERSION?m=text | head -n1 | sed 's/go//')
                echo "Detected latest Go version: $GO_VERSION"
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
    fi

    # Install Zig 0.16 (latest from master builds)
    if ! command_exists zig; then
        echo "⚡ Installing Zig 0.16 (latest master build)..."
        case $OS in
            linux|debian|fedora|arch)
                # Fetch the latest 0.16.0-dev build
                echo "Fetching latest Zig 0.16 master build..."

                # Get the download page and extract the latest 0.16 tarball URL
                ZIG_URL=$(curl -sL https://ziglang.org/download/ | grep -oP 'https://ziglang.org/builds/zig-linux-x86_64-0\.16\.0-dev\.[0-9]+\+[a-f0-9]+\.tar\.xz' | head -n1)

                if [ -z "$ZIG_URL" ]; then
                    echo "Could not find Zig 0.16 build, falling back to latest stable..."
                    ZIG_URL="https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz"
                fi

                echo "Downloading from: $ZIG_URL"
                wget -q "$ZIG_URL" -O zig.tar.xz

                # Extract version from filename for directory naming
                ZIG_DIR=$(basename "$ZIG_URL" .tar.xz)

                sudo rm -rf /usr/local/zig-linux-x86_64-*
                sudo tar -C /usr/local -xJf zig.tar.xz
                sudo ln -sf "/usr/local/${ZIG_DIR}/zig" /usr/local/bin/zig
                rm zig.tar.xz

                echo "Installed: $(zig version)"
                ;;
            macos)
                # macOS: use master builds
                brew install zig --HEAD || brew install zig
                ;;
        esac
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

# Check Treesitter parsers
echo ""
echo "🌳 Checking Treesitter Parsers:"
TREESITTER_DIR="$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"
if [ -d "$TREESITTER_DIR" ]; then
    for lang in rust go zig; do
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
echo "  • File explorer: <Space>e"
echo "  • Find files: <Space>ff"
echo "  • Live grep: <Space>fg"
echo "  • LSP hover: K"
echo "  • Go to definition: gd"
echo "  • Rename: <Space>rn"
echo "  • Code action: <Space>ca"
echo "  • Format: <Space>f"
echo ""
echo "🚀 Run 'nvim' to start coding with full Zig, Rust, and Go support!"