local plugin = {
  "BrightXiaoHan/nvim-trzsz",
  dependencies = { "nvim-tree/nvim-tree.lua" },
  init = function()
    if vim.env.SSH_TTY then
      vim.keymap.set(
        "n",
        "<M-r>",
        require("nvim-trzsz").nvim_tree_trz,
        { noremap = true, silent = true, desc = "Trz: upload file" }
      )

      vim.keymap.set(
        "n",
        "<M-s>",
        require("nvim-trzsz").nvim_tree_tsz,
        { noremap = true, silent = true, desc = "Tsz: download file" }
      )
    end
  end,
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
