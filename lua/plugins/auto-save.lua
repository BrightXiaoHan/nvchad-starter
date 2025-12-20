local plugin = {
  "okuuva/auto-save.nvim",
  cmd = "ASToggle", -- optional for lazy loading on command
  event = { "InsertLeave", "TextChangedI" }, -- optional for lazy loading on trigger events
  opts = {
    debounce_delay = 1000,
    trigger_events = { "InsertLeave", "TextChangedI" },
  },
  keys = {
    { "<leader>n", "<cmd>ASToggle<CR>", desc = "Toggle auto-save" },
  },
}

return plugin
