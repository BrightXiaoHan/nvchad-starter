local plugin = {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "sindrets/diffview.nvim", -- optional - Diff integration
  },
  config = true,
  init = function()
    vim.keymap.set("n", "<leader>gm", "<cmd>lua require'neogit'.open({ kind = 'split' })<CR>", {
      desc = "Open Neogit",
    })
  end,
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
