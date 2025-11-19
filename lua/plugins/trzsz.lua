local plugin = {
  "BrightXiaoHan/nvim-trzsz",
  dependencies = { "nvim-tree/nvim-tree.lua" },
  keys = {
    {
      "<M-r>",
      function()
        require("nvim-trzsz").nvim_tree_trz()
      end,
      desc = "Trz: upload file",
      noremap = true,
      silent = false,
    },
    {
      "<M-s>",
      function()
        require("nvim-trzsz").nvim_tree_tsz()
      end,
      desc = "Tsz: download file",
      noremap = true,
      silent = false,
    },
    {
      "<M-o>",
      function()
        require("nvim-trzsz").nvim_tree_open()
      end,
      desc = "Tsz: open file",
      noremap = true,
      silent = false,
    },
  },
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
