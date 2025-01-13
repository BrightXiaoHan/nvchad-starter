local plugin = {
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
}

return plugin
