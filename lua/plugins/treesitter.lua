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
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
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
  config = function(_, opts)
    require("nvim-treesitter").setup(opts)
  end,
  build = ":TSUpdate",
}
return plugin
