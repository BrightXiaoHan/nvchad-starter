local function init()
  local map = vim.keymap.set

  map("n", "<leader>gf", "<cmd>Fugit2<cr>", {
    desc = "Fugit status",
  })
  map("n", "<leader>gg", "<cmd>Fugit2Graph<cr>", {
    desc = "Fugit graph",
  })
end

local plugin = {
  "SuperBo/fugit2.nvim",
  build = false,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim",
    {
      "chrisgrieser/nvim-tinygit",
      dependencies = { "stevearc/dressing.nvim" },
    },
  },
  cmd = { "Fugit2", "Fugit2Diff", "Fugit2Graph" },
  opts = {
    width = 100,
  },
  init = init,
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
