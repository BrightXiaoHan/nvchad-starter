local opts = {
  mapping = {
    ["<Up>"] = require("cmp").mapping.select_prev_item(),
    ["<Down>"] = require("cmp").mapping.select_next_item(),
    ["<C-e>"] = require("cmp").mapping.close(),
    ["<Tab>"] = require("cmp").config.disable,
  },
  sources = {
    { name = "path" },
    { name = "nvim_lsp", max_item_count = 3 },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "treesitter" },
  },
  -- disable auto-complete
  -- completion = {
  -- 	autocomplete = false,
  -- },
}

local plugin = {
  "hrsh7th/nvim-cmp",
  opts = opts,
}

return plugin
