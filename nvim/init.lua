-- Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"                  -- Enable mouse
vim.opt.clipboard = "unnamedplus"    -- Use system clipboard
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.updatetime = 250
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- VS Code-like keybindings
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save" })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { desc = "Save" })
vim.keymap.set("n", "<C-z>", "u", { desc = "Undo" })
vim.keymap.set("i", "<C-z>", "<Esc>ui", { desc = "Undo" })
vim.keymap.set("n", "<C-y>", "<C-r>", { desc = "Redo" })
vim.keymap.set("v", "<C-c>", '"+y', { desc = "Copy" })
vim.keymap.set("n", "<C-v>", '"+p', { desc = "Paste" })
vim.keymap.set("i", "<C-v>", '<Esc>"+pa', { desc = "Paste" })
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })
vim.keymap.set("n", "<C-f>", "/", { desc = "Find" })
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search" })

-- Tab navigation
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<C-S-Tab>", ":bprevious<CR>", { desc = "Previous tab" })
vim.keymap.set("n", "<C-w>", ":bdelete<CR>", { desc = "Close tab" })

-- Window navigation with Ctrl+Arrow
vim.keymap.set("n", "<C-Left>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-Down>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-Up>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Move to right window" })

-- Indent with Tab in visual mode
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Unindent" })

-- Open file explorer on startup (like VS Code)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only if no file was opened
    if vim.fn.argc() == 0 then
      vim.cmd("Neotree show")
    end
  end,
})

-- Plugins
require("lazy").setup({
  -- Color scheme (high contrast dark)
  {
    "projekt0n/github-nvim-theme",
    priority = 1000,
    config = function()
      require("github-theme").setup({})
      vim.cmd("colorscheme github_dark_high_contrast")
    end,
  },

  -- File explorer (Ctrl+b to toggle, like VS Code)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,  -- Load immediately
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<C-b>", ":Neotree toggle<CR>", desc = "Toggle file explorer" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        window = { width = 30 },
      })
    end,
  },

  -- Fuzzy finder (Ctrl+p for files, Ctrl+Shift+f for grep)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", ":Telescope find_files<CR>", desc = "Find files" },
      { "<C-S-f>", ":Telescope live_grep<CR>", desc = "Search in files" },
    },
  },

  -- Tabs/bufferline
  {
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          show_buffer_close_icons = true,
          show_close_icon = false,
        },
      })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("lualine").setup({
        options = { theme = "auto" },
      })
    end,
  },

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Show keybinding hints (press any key and wait)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        delay = 300,  -- Show after 300ms
      })
    end,
  },

  -- Auto pairs (brackets, quotes)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Comment toggle (Ctrl+/ to comment)
  {
    "numToStr/Comment.nvim",
    keys = {
      { "<C-/>", "<Plug>(comment_toggle_linewise_current)", desc = "Toggle comment" },
      { "<C-/>", "<Plug>(comment_toggle_linewise_visual)", mode = "v", desc = "Toggle comment" },
    },
    config = function()
      require("Comment").setup()
    end,
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if ok then
        configs.setup({
          ensure_installed = { "lua", "python", "javascript", "bash", "json", "yaml", "markdown" },
          auto_install = true,
          highlight = { enable = true },
        })
      end
    end,
  },
})
