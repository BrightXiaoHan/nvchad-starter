local plugin = {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = "Telescope",
  opts = function()
    return require "nvchad.configs.telescope"
  end,
  init = function()
    -- Telescope mappings
    vim.keymap.set("n", "<C-p>", ":Telescope find_files<CR>", {
      desc = "Find file",
    })
    vim.keymap.set("n", "<C-f>", ":Telescope live_grep<CR>", {
      desc = "Fuzzy find",
    })
    vim.keymap.set("n", "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<cr>", {
      desc = "Find",
    })
  end,
}

return plugin
