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

-- Clipboard configuration for Wayland/Crostini
vim.g.clipboard = {
  name = 'WaylandClipboard',
  copy = {
    ['+'] = 'wl-copy',
    ['*'] = 'wl-copy',
  },
  paste = {
    ['+'] = 'wl-paste --no-newline',
    ['*'] = 'wl-paste --no-newline',
  },
  cache_enabled = 0,
}

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
      -- Rust analyzer
      vim.lsp.config['rust-analyzer'] = {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", ".git" },
      }

      -- Go language server
      vim.lsp.config.gopls = {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/gopls" },
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
      vim.lsp.enable("rust-analyzer")
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
      ensure_installed = { "zig", "rust", "go", "lua", "vim", "vimdoc" },
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
    branch = "0.1.x",
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

  -- Multi-cursor support (VSCode-style)
  {
    "mg979/vim-visual-multi",
    branch = "master",
  },

})

-- Additional keybindings
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Paste from Chrome OS clipboard (workaround for Crostini)
vim.keymap.set({"n", "v", "i"}, "<C-S-v>", function()
  local clip = vim.fn.system("wl-paste --no-newline")
  if vim.fn.mode() == "i" then
    vim.api.nvim_put({clip}, "c", true, true)
  else
    vim.api.nvim_put(vim.split(clip, "\n"), "l", true, true)
  end
end, { desc = "Paste from Chrome OS" })
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
