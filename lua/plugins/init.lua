local overrides = require "configs.overrides"

---@type NvPluginSpec[]
local plugins = { -- Override plugin definition options
  {
    "stevearc/conform.nvim",
    --  for users those who want auto-save conform + lazyloading!
    -- event = "BufWritePre"
    config = function()
      require "configs.conform"
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
    lazy = false,
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  }, -- Install a plugin
  {
    "hrsh7th/nvim-cmp",
    opts = overrides.cmp,
  },
  {
    "Nvchad/nvterm",
    opts = overrides.nvterm,
  },
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
  {
    "github/copilot.vim",
    lazy = false,
  },
  {
    "Pocco81/auto-save.nvim",
    lazy = false,
  },
  {
    "stevearc/aerial.nvim",
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      require("aerial").setup {
        layout = {
          max_width = { 40, 0.2 },
          min_width = 25,
        },
      }
    end,
  },
  {
    {
      "willothy/flatten.nvim",
      -- config = true,
      -- or pass configuration with
      opts = function()
        return {
          window = {
            open = "tab",
          },
        }
      end,
      -- Ensure that it runs first to minimize delay when opening file from terminal
      lazy = false,
      priority = 1001,
    }, --- ...
  },
  {
    "nvim-pack/nvim-spectre",
    requires = { { "nvim-lua/plenary.nvim" } },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua", -- optional
    },
    config = true,
    lazy = false,
  },
}

return plugins
