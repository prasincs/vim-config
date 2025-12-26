-- Neovim configuration with Zig LSP support
-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.colorcolumn = "100"

-- Clipboard configuration (macOS uses pbcopy/pbpaste by default)
-- Uncomment below for Wayland/Crostini if needed
-- vim.g.clipboard = {
--   name = 'WaylandClipboard',
--   copy = {
--     ['+'] = 'wl-copy',
--     ['*'] = 'wl-copy',
--   },
--   paste = {
--     ['+'] = 'wl-paste --no-newline',
--     ['*'] = 'wl-paste --no-newline',
--   },
--   cache_enabled = 0,
-- }

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Plugin setup
require("lazy").setup({
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason for managing LSP servers (optional)
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",

      -- Useful status updates for LSP
      { "j-hui/fidget.nvim", opts = {} },

      -- Additional lua configuration for neovim
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      -- Setup Mason
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "rust_analyzer", "gopls" },
        automatic_installation = true,
      })

      -- Setup LSP servers using the modern vim.lsp.config API
      -- Rust analyzer (uses rust-analyzer from PATH or Mason)
      vim.lsp.config['rust_analyzer'] = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", ".git" },
      }

      -- Go language server (uses gopls from PATH or Mason)
      vim.lsp.config.gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.mod", ".git", "go.work" },
      }

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })

      -- Setup ZLS (Zig Language Server)
      vim.lsp.config.zls = {
        cmd = { "zls" },
        filetypes = { "zig", "zir" },
        root_markers = { "zls.json", ".git", "build.zig" },
      }

      -- Enable all configured LSP servers
      vim.lsp.enable("zls")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("gopls")
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = { "zig", "rust", "go", "lua", "vim", "vimdoc", "markdown", "markdown_inline" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end,
  },

  -- Color scheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
        },
      })
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Comment toggling
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Zen mode for distraction-free writing
  {
    "folke/zen-mode.nvim",
    opts = {},
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
  },

  -- Dim inactive text while writing
  {
    "folke/twilight.nvim",
    opts = {},
  },

  -- Markdown rendering in-buffer
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {},
  },

  -- Code outline/navigation (works with LSP + Treesitter)
  {
    "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      backends = { "treesitter", "lsp", "markdown", "man" },
      layout = {
        min_width = 30,
        default_direction = "right",
      },
      filter_kind = false, -- show all symbol types
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Toggle outline" },
      { "<leader>O", "<cmd>AerialNavToggle<cr>", desc = "Toggle outline nav" },
      { "{", "<cmd>AerialPrev<cr>", desc = "Previous symbol" },
      { "}", "<cmd>AerialNext<cr>", desc = "Next symbol" },
    },
  },

  -- Multi-cursor support (VSCode-style)
  {
    "mg979/vim-visual-multi",
    branch = "master",
  },

  -- Snacks.nvim (required for claudecode.nvim terminal)
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {},
  },

  -- Claude Code AI integration
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal_cmd = vim.fn.expand("~/.claude/local/claude"),
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject diff" },
    },
  },

})

-- Additional keybindings
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])
vim.keymap.set("n", "Q", "<nop>")

-- Disable Ctrl-Z in ClaudeCode terminal (prevents accidental suspend)
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    -- Check buffer name or terminal command for claude
    local bufname = vim.api.nvim_buf_get_name(0):lower()
    if bufname:match("claude") or bufname:match("ClaudeCode") then
      vim.keymap.set("t", "<C-z>", "<nop>", { buffer = 0 })
    end
    -- Also set after a short delay to catch dynamically named terminals
    vim.defer_fn(function()
      local name = vim.api.nvim_buf_get_name(0):lower()
      if name:match("claude") then
        vim.keymap.set("t", "<C-z>", "<nop>", { buffer = 0 })
      end
    end, 100)
  end,
})

-- Diagnostic configuration
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

-- Zig configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "zig",
  callback = function()
    -- Set makeprg to use zig build
    vim.opt_local.makeprg = "zig build"

    -- Set errorformat for Zig compiler errors
    vim.opt_local.errorformat = "%f:%l:%c: %t%*[^:]: %m"
  end,
})

-- Rust configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    -- Set makeprg to use cargo
    vim.opt_local.makeprg = "cargo build"

    -- Set errorformat for rustc compiler errors
    vim.opt_local.errorformat =
      "%E--> %f:%l:%c," ..
      "%W--> %f:%l:%c," ..
      "%C%m"
  end,
})

-- Go configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    -- Set makeprg to use go build
    vim.opt_local.makeprg = "go build"

    -- Set errorformat for Go compiler errors
    vim.opt_local.errorformat = "%f:%l:%c: %m,%f:%l: %m"
  end,
})

-- Markdown/prose configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
    vim.opt_local.conceallevel = 2
  end,
})

-- Markdown image helper functions
local function get_images_dir()
  -- Look for common blog static directories, fallback to ./images
  local candidates = { "static/images", "assets/images", "public/images", "images" }
  local cwd = vim.fn.getcwd()
  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(cwd .. "/" .. dir) == 1 then
      return dir
    end
  end
  return "images"
end

local function insert_markdown_image(image_path)
  local filename = vim.fn.fnamemodify(image_path, ":t")
  local images_dir = get_images_dir()
  local dest_path = images_dir .. "/" .. filename
  local full_dest = vim.fn.getcwd() .. "/" .. dest_path

  -- Create images directory if it doesn't exist
  vim.fn.mkdir(vim.fn.fnamemodify(full_dest, ":h"), "p")

  -- Copy file
  local result = vim.fn.system({ "cp", vim.fn.expand(image_path), full_dest })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to copy image: " .. result, vim.log.levels.ERROR)
    return
  end

  -- Insert markdown image tag at cursor
  local md_tag = string.format("![%s](/%s)", vim.fn.fnamemodify(filename, ":r"), dest_path)
  vim.api.nvim_put({ md_tag }, "c", true, true)
  vim.notify("Inserted: " .. dest_path, vim.log.levels.INFO)
end

local function paste_image_from_clipboard(custom_name)
  -- Check if pngpaste is available
  if vim.fn.executable("pngpaste") ~= 1 then
    vim.notify("pngpaste not found. Install with: brew install pngpaste", vim.log.levels.ERROR)
    return
  end

  local images_dir = get_images_dir()
  local timestamp = os.date("%Y%m%d-%H%M%S")
  local basename = custom_name or ("screenshot-" .. timestamp)
  -- Ensure .png extension
  local filename = basename:match("%.png$") and basename or (basename .. ".png")
  local dest_path = images_dir .. "/" .. filename
  local full_dest = vim.fn.getcwd() .. "/" .. dest_path

  -- Create images directory if it doesn't exist
  vim.fn.mkdir(vim.fn.fnamemodify(full_dest, ":h"), "p")

  -- Save clipboard image using pngpaste
  local result = vim.fn.system({ "pngpaste", full_dest })
  if vim.v.shell_error ~= 0 then
    vim.notify("No image in clipboard or paste failed", vim.log.levels.WARN)
    return
  end

  -- Insert markdown image tag at cursor
  local alt_text = vim.fn.fnamemodify(filename, ":r")
  local md_tag = string.format("![%s](/%s)", alt_text, dest_path)
  vim.api.nvim_put({ md_tag }, "c", true, true)
  vim.notify("Pasted: " .. dest_path, vim.log.levels.INFO)
end

-- Command: :MarkdownInsertImage ~/path/to/image.png
vim.api.nvim_create_user_command("MarkdownInsertImage", function(opts)
  if opts.args == "" then
    vim.notify("Usage: :MarkdownInsertImage <path>", vim.log.levels.WARN)
    return
  end
  insert_markdown_image(opts.args)
end, { nargs = 1, complete = "file", desc = "Insert image into markdown" })

-- Keymap for pasting from clipboard (markdown files only)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<leader>mi", function() paste_image_from_clipboard() end, { buffer = true, desc = "Paste image from clipboard" })
    vim.keymap.set("n", "<leader>mn", function()
      vim.ui.input({ prompt = "Image name: " }, function(name)
        if name and name ~= "" then paste_image_from_clipboard(name) end
      end)
    end, { buffer = true, desc = "Paste image with custom name" })
    vim.keymap.set("n", "<leader>mI", function()
      vim.ui.input({ prompt = "Image path: ", completion = "file" }, function(path)
        if path then insert_markdown_image(path) end
      end)
    end, { buffer = true, desc = "Insert image from path" })
  end,
})

-- Build and run keymaps (language-aware)
-- These work with makeprg set by FileType autocmds
vim.keymap.set("n", "<leader>m", ":make<CR>", { desc = "Build with :make" })
vim.keymap.set("n", "<leader>M", ":make ", { desc = "Build with custom args" })

-- Language-specific run and test commands
vim.keymap.set("n", "<leader>r", function()
  local ft = vim.bo.filetype
  if ft == "zig" then
    vim.cmd("make run")
  elseif ft == "rust" then
    vim.cmd("!cargo run")
  elseif ft == "go" then
    vim.cmd("!go run .")
  else
    print("Run not configured for filetype: " .. ft)
  end
end, { desc = "Build and Run (quickfix)" })

vim.keymap.set("n", "<leader>t", function()
  local ft = vim.bo.filetype
  if ft == "zig" then
    vim.cmd("make test")
  elseif ft == "rust" then
    vim.cmd("!cargo test")
  elseif ft == "go" then
    vim.cmd("!go test")
  else
    print("Test not configured for filetype: " .. ft)
  end
end, { desc = "Run Tests" })

-- Terminal-based run (output stays visible, can copy from it)
vim.keymap.set("n", "<leader>rr", function()
  local ft = vim.bo.filetype
  local cmd
  if ft == "zig" then
    cmd = "zig build run"
  elseif ft == "rust" then
    cmd = "cargo run"
  elseif ft == "go" then
    cmd = "go run ."
  else
    print("Run not configured for filetype: " .. ft)
    return
  end
  vim.cmd("split | terminal " .. cmd)
  vim.cmd("startinsert")
end, { desc = "Run in terminal (persistent output)" })

vim.keymap.set("n", "<leader>rt", function()
  local ft = vim.bo.filetype
  local cmd
  if ft == "zig" then
    cmd = "zig build test"
  elseif ft == "rust" then
    cmd = "cargo test"
  elseif ft == "go" then
    cmd = "go test"
  else
    print("Test not configured for filetype: " .. ft)
    return
  end
  vim.cmd("split | terminal " .. cmd)
  vim.cmd("startinsert")
end, { desc = "Test in terminal (persistent output)" })

-- Quickfix navigation
vim.keymap.set("n", "<leader>co", ":copen<CR>", { desc = "Open quickfix list" })
vim.keymap.set("n", "<leader>cc", ":cclose<CR>", { desc = "Close quickfix list" })
vim.keymap.set("n", "[q", ":cprev<CR>", { desc = "Previous quickfix item" })
vim.keymap.set("n", "]q", ":cnext<CR>", { desc = "Next quickfix item" })

-- Copy all quickfix errors to clipboard
vim.keymap.set("n", "<leader>ce", function()
  local qf_list = vim.fn.getqflist()
  local errors = {}
  for _, item in ipairs(qf_list) do
    local bufname = vim.fn.bufname(item.bufnr)
    local line = string.format("%s:%d:%d: %s", bufname, item.lnum, item.col, item.text)
    table.insert(errors, line)
  end
  local error_text = table.concat(errors, "\n")
  vim.fn.setreg("+", error_text)
  print("Copied " .. #errors .. " errors to clipboard")
end, { desc = "Copy all errors to clipboard" })

-- Quick run current file (for single-file programs)
vim.keymap.set("n", "<leader>zf", ":!zig run %<CR>", { desc = "Zig Run Current File" })
vim.keymap.set("n", "<leader>rf", ":!rustc % && ./%:t:r<CR>", { desc = "Rust Run Current File" })
vim.keymap.set("n", "<leader>gf", ":!go run %<CR>", { desc = "Go Run Current File" })
-- clear ^@ characters
vim.keymap.set('n', '<leader>fn', ':%s/\\%x00/\\r/g<CR>', { desc = 'Fix null bytes to newlines' })
