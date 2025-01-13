local opts = {
  ensure_installed = {
    "lua",
    "c",
    "cpp",
    "fish",
    "python",
    "bash",
    "markdown",
    "cmake",
    "dockerfile",
    "yaml",
  },
  indent = {
    enable = true,
    disable = {},
  },
}

local plugin = {
  "nvim-treesitter/nvim-treesitter",
  opts = opts,
  lazy = false,
}
return plugin
