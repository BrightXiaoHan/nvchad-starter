local local_trzsz = vim.fn.expand("~/gitrepo/nvim-trzsz")
local use_local = vim.fn.isdirectory(local_trzsz) == 1

local plugin

if use_local then
  plugin = {
    dir = local_trzsz,
    name = "nvim-trzsz",
    dependencies = { "nvim-tree/nvim-tree.lua" },
  }
else
  plugin = {
    "BrightXiaoHan/nvim-trzsz",
    dependencies = { "nvim-tree/nvim-tree.lua" },
  }
end

plugin.keys = {
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
  }
plugin.cond = function()
  return not vim.g.vscode
end

return plugin
