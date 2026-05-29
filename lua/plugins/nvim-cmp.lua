local opts = function()
  local cmp = require "cmp"
  local opts = {
    mapping = {
      ["<Up>"] = cmp.mapping.select_prev_item(),
      ["<Down>"] = cmp.mapping.select_next_item(),
      ["<C-e>"] = cmp.mapping.close(),
      ["<Tab>"] = cmp.config.disable,
    },
    sources = {
      { name = "path" },
      { name = "nvim_lsp", max_item_count = 3 },
      { name = "buffer" },
      { name = "nvim_lua" },
    },
    -- disable auto-complete
    -- completion = {
    -- 	autocomplete = false,
    -- },
    enabled = function()
      return not vim.g.vscode
    end,
  }
  return opts
end

local plugin = {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-path",
  },
  main = "cmp",
  opts = opts,
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
