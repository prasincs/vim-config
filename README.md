# Neovim Configuration (2025)

Modern Neovim configuration with LSP, Tree-sitter, and Zig development support.

This is a complete rewrite of my [original Vim configuration](https://github.com/prasincs/vim-config) using Lua and modern Neovim features.

## Features

### Core Setup
- **Plugin Manager**: [lazy.nvim](https://github.com/folke/lazy.nvim) - Fast and modern plugin manager
- **Language Server Protocol (LSP)**: Full IDE-like features with nvim-lspconfig
- **Syntax Highlighting**: Tree-sitter for advanced syntax highlighting
- **Autocompletion**: nvim-cmp with LSP, buffer, path, and snippet sources
- **Fuzzy Finding**: Telescope for file/text search
- **File Explorer**: nvim-tree with web devicons

### Language Support
- **Zig**: Full ZLS (Zig Language Server) integration with build/test/run keymaps
- **Lua**: Neodev for Neovim Lua API support
- Auto-install Tree-sitter parsers for any language

### Additional Plugins
- **Git Integration**: gitsigns for inline git changes
- **Status Line**: lualine with Tokyo Night theme
- **Comments**: Comment.nvim for smart commenting
- **Multi-cursor**: vim-visual-multi for VSCode-style multi-cursor editing
- **Color Scheme**: Tokyo Night

### Chrome OS / Crostini Specific
- Wayland clipboard integration (wl-copy/wl-paste)
- Custom paste bindings for Chrome OS clipboard
- Optimized for Crostini/Linux container environments

## Installation

### Prerequisites

```bash
# Neovim 0.9+ required
nvim --version

# Install required tools
# For Ubuntu/Debian (Crostini):
sudo apt install ripgrep fd-find wl-clipboard

# For Zig development:
# Install Zig: https://ziglang.org/download/
# Install ZLS: https://github.com/zigtools/zls
```

### Setup

1. **Clone this repository**:
   ```bash
   git clone https://github.com/prasincs/vim-config.git ~/vim-config
   ```

2. **Create symbolic links**:
   ```bash
   # Backup existing config if you have one
   mv ~/.config/nvim ~/.config/nvim.backup

   # Create symlink to config directory
   ln -s ~/vim-config ~/.config/nvim
   ```

3. **Launch Neovim**:
   ```bash
   nvim
   ```

   Lazy.nvim will automatically install all plugins on first launch.

### GUI Configuration (Optional)

If using a GUI like neovim-qt, the `ginit.vim` file configures:
- JetBrains Mono Nerd Font (size 12)
- Line spacing for better readability

Install a [Nerd Font](https://www.nerdfonts.com/) for proper icon display.

## Keybindings

### Leader Key
- Leader: `<Space>`

### File Operations
- `<leader>e` - Toggle file explorer (nvim-tree)
- `<leader>pv` - Open netrw (built-in file explorer)
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep (search in files)
- `<leader>fb` - Browse open buffers
- `<leader>fh` - Search help tags

### LSP (when attached to buffer)
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - List references
- `K` - Hover documentation
- `<C-k>` - Signature help
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions
- `<leader>f` - Format buffer
- `<leader>D` - Type definition

### Diagnostics
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `<leader>dl` - Diagnostic list
- `<leader>q` - Open diagnostic quickfix list

### Zig Development
- `<leader>m` - Build project (`zig build`)
- `<leader>r` - Build and run (quickfix mode)
- `<leader>t` - Build and test
- `<leader>M` - Build with custom args
- `<leader>R` - Run with custom args
- `<leader>rr` - Run in terminal (persistent output)
- `<leader>rt` - Test in terminal (persistent output)
- `<leader>zf` - Quick run current file

### Quickfix List
- `<leader>co` - Open quickfix list
- `<leader>cc` - Close quickfix list
- `[q` - Previous quickfix item
- `]q` - Next quickfix item
- `<leader>ce` - Copy all errors to clipboard

### Editing
- `J`/`K` (visual) - Move selected lines up/down
- `<C-d>`/`<C-u>` - Half-page down/up (centered)
- `n`/`N` - Next/previous search (centered)
- `<leader>y` - Yank to system clipboard
- `<leader>p` (visual) - Paste without overwriting register
- `<leader>d` - Delete to black hole register
- `gcc` - Toggle line comment (Comment.nvim)
- `gc` (visual) - Toggle comment on selection

### Chrome OS Specific
- `<C-S-v>` - Paste from Chrome OS clipboard (all modes)
- `<leader>fn` - Fix null bytes to newlines

## Configuration Structure

```
~/.config/nvim/
├── init.lua           # Main configuration file
├── ginit.vim          # GUI-specific settings
└── lazy-lock.json     # Plugin version lockfile (auto-generated)
```

All configuration is in a single `init.lua` file for simplicity. For larger configs, consider splitting into:
- `lua/plugins/` - Plugin specifications
- `lua/config/` - Settings and keymaps
- `after/ftplugin/` - Filetype-specific settings

## Migration from Old Vim Config

This config replaces the old Pathogen-based Vim setup with:

| Old (Vim) | New (Neovim) |
|-----------|--------------|
| Pathogen | lazy.nvim |
| Syntastic | nvim LSP + diagnostics |
| Ctrl-P | Telescope |
| NERDTree | nvim-tree |
| Powerline | lualine |
| Manual syntax | Tree-sitter |
| NERDCommenter | Comment.nvim |
| Fugitive | gitsigns (+ git via terminal) |

## Customization

### Local Overrides
Create `~/.config/nvim/lua/local.lua` for machine-specific settings and require it at the end of `init.lua`.

### Adding Plugins
Edit the `require("lazy").setup({...})` section in `init.lua` and add plugin specs. See [lazy.nvim documentation](https://github.com/folke/lazy.nvim).

### Adding Language Servers
Use Mason's UI (`:Mason`) or add to `ensure_installed` in the mason-lspconfig setup.

## Troubleshooting

### Clipboard not working
Ensure `wl-clipboard` is installed:
```bash
sudo apt install wl-clipboard
wl-paste --version
```

### LSP not attaching
1. Check if language server is installed: `:Mason`
2. Check LSP status: `:LspInfo`
3. Check logs: `:lua vim.cmd('e'..vim.lsp.get_log_path())`

### Plugins not loading
1. Update lazy.nvim: `:Lazy sync`
2. Check for errors: `:Lazy log`
3. Clean and reinstall: `:Lazy clean` then `:Lazy install`

## License

Feel free to use this configuration for your own setup. No warranty provided.

## Evolution

- **2010-2020**: Original Vim config with Pathogen and Vimscript
- **2025**: Complete rewrite for Neovim with Lua, LSP, and modern tooling
