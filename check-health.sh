#!/bin/bash

# Neovim Development Environment Health Check
# Run this anytime to verify your setup

echo "╔════════════════════════════════════════════╗"
echo "║  Neovim Development Environment Check     ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Helper functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_component() {
    local name="$1"
    local command="$2"

    if eval "$command" >/dev/null 2>&1; then
        echo "✅ $name: OK"
        return 0
    else
        echo "❌ $name: FAILED"
        return 1
    fi
}

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check Neovim
echo "🎯 Core Components:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if check_component "Neovim" "nvim --version"; then
    ((CHECKS_PASSED++))
    echo "   $(nvim --version | head -n1)"
else
    ((CHECKS_FAILED++))
    echo "   Install: https://github.com/neovim/neovim/releases"
fi

if check_component "Config file" "test -f ~/.config/nvim/init.lua"; then
    ((CHECKS_PASSED++))
    echo "   Location: ~/.config/nvim/init.lua"
else
    ((CHECKS_FAILED++))
    echo "   Missing: ~/.config/nvim/init.lua"
fi

# Check plugins
echo ""
echo "🔌 Plugins:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if check_component "Lazy.nvim" "test -d ~/.local/share/nvim/lazy/lazy.nvim"; then
    ((CHECKS_PASSED++))
    PLUGIN_COUNT=$(ls -1 ~/.local/share/nvim/lazy/ 2>/dev/null | wc -l)
    echo "   $PLUGIN_COUNT plugins installed"
else
    ((CHECKS_FAILED++))
    echo "   Run: nvim (plugins will auto-install)"
fi

if check_component "Mason" "test -d ~/.local/share/nvim/mason"; then
    ((CHECKS_PASSED++))
    if [ -d ~/.local/share/nvim/mason/bin ]; then
        LSP_COUNT=$(ls -1 ~/.local/share/nvim/mason/bin/ 2>/dev/null | wc -l)
        echo "   $LSP_COUNT language servers installed"
    fi
else
    ((CHECKS_FAILED++))
fi

# Check language servers
echo ""
echo "🔧 Language Servers:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if check_component "rust-analyzer" "test -x ~/.local/share/nvim/mason/bin/rust-analyzer"; then
    ((CHECKS_PASSED++))
    echo "   $(~/.local/share/nvim/mason/bin/rust-analyzer --version 2>&1)"
else
    ((CHECKS_FAILED++))
    echo "   Install: :MasonInstall rust-analyzer"
fi

if check_component "gopls" "test -x ~/.local/share/nvim/mason/bin/gopls"; then
    ((CHECKS_PASSED++))
    echo "   $(~/.local/share/nvim/mason/bin/gopls version 2>&1 | head -n1)"
else
    ((CHECKS_FAILED++))
    echo "   Install: :MasonInstall gopls"
    echo "   Note: Requires Go to be installed first"
fi

if command_exists zls; then
    if check_component "zls" "zls --version"; then
        ((CHECKS_PASSED++))
        echo "   $(zls --version 2>&1 | head -n1)"
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ zls: Not in PATH (using manual install or Mason)"
fi

# Check language toolchains
echo ""
echo "🔨 Language Toolchains:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command_exists rustc; then
    if check_component "Rust" "rustc --version"; then
        ((CHECKS_PASSED++))
        echo "   $(rustc --version)"
        if command_exists cargo; then
            echo "   $(cargo --version)"
        fi
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ Rust: Not installed"
    echo "   Install: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

if command_exists go; then
    if check_component "Go" "go version"; then
        ((CHECKS_PASSED++))
        echo "   $(go version)"
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ Go: Not installed"
    echo "   Install: https://go.dev/dl/"
fi

if command_exists zig; then
    if check_component "Zig" "zig version"; then
        ((CHECKS_PASSED++))
        echo "   $(zig version)"
    else
        ((CHECKS_FAILED++))
    fi
else
    echo "⚪ Zig: Not installed"
    echo "   Install: https://ziglang.org/download/"
fi

# Check Treesitter parsers
echo ""
echo "🌳 Treesitter Parsers:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TREESITTER_DIR="$HOME/.local/share/nvim/lazy/nvim-treesitter/parser"
if [ -d "$TREESITTER_DIR" ]; then
    PARSER_COUNT=0
    for lang in rust go zig lua vim vimdoc; do
        if [ -f "$TREESITTER_DIR/${lang}.so" ]; then
            echo "✅ ${lang}.so"
            ((PARSER_COUNT++))
        fi
    done
    if [ $PARSER_COUNT -eq 0 ]; then
        echo "⚠️  No parsers compiled yet"
        echo "   Open a file in nvim to trigger compilation"
    fi
else
    echo "⚠️  Parser directory not found"
    echo "   Will be created on first nvim run"
fi

# Check clipboard support
echo ""
echo "📋 Clipboard Support:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$XDG_SESSION_TYPE" == "wayland" ]] || [[ -n "$SOMMELIER_VERSION" ]]; then
    if command_exists wl-copy && command_exists wl-paste; then
        if check_component "Wayland clipboard" "wl-paste --version"; then
            ((CHECKS_PASSED++))
            echo "   $(wl-paste --version)"
        else
            ((CHECKS_FAILED++))
        fi
    else
        echo "⚠️  wl-clipboard not installed"
        echo "   Install: sudo apt install wl-clipboard"
    fi
elif command_exists xclip || command_exists xsel; then
    echo "✅ X11 clipboard: OK"
    ((CHECKS_PASSED++))
else
    echo "⚠️  No clipboard tool found"
    echo "   Install: sudo apt install xclip"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║              Summary                        ║"
echo "╠════════════════════════════════════════════╣"
printf "║  ✅ Passed: %-31s ║\n" "$CHECKS_PASSED"
if [ $CHECKS_FAILED -gt 0 ]; then
    printf "║  ❌ Failed: %-31s ║\n" "$CHECKS_FAILED"
    echo "╠════════════════════════════════════════════╣"
    echo "║  ⚠️  Some checks failed!                   ║"
    echo "║  Review the output above for details.     ║"
    echo "╚════════════════════════════════════════════╝"
    exit 1
else
    printf "║  ❌ Failed: %-31s ║\n" "0"
    echo "╠════════════════════════════════════════════╣"
    echo "║  ✅ All critical checks passed!            ║"
    echo "║                                            ║"
    echo "║  Your Neovim is ready for:                ║"
    echo "║    • Zig development                       ║"
    echo "║    • Rust development                      ║"
    echo "║    • Go development                        ║"
    echo "╚════════════════════════════════════════════╝"
    exit 0
fi