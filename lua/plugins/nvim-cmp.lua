local opts = function()
  cmp = require "nvim-cmp"
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
      { name = "treesitter" },
    },
    -- disable auto-complete
    -- completion = {
    -- 	autocomplete = false,
    -- },
    cond = function()
      return not vim.g.vscode
    end,
  }
  return opts
end

local plugin = {
  "hrsh7th/nvim-cmp",
  opts = opts,
}

return plugin
