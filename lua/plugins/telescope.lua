local plugin = {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = "Telescope",
  opts = {
    defaults = {
      prompt_prefix = "   ",
      selection_caret = " ",
      entry_prefix = " ",
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
        },
        width = 0.87,
        height = 0.80,
      },
      mappings = {
        n = { ["q"] = require("telescope.actions").close },
      },
    },
    extensions_list = { "themes", "terms" },
    extensions = {},
  },
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
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
