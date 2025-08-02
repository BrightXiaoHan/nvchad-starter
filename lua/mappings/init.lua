-- Mappings module init file
-- This file is loaded when require("mappings") is called

local map = vim.keymap.set

-- General mappings
map("n", ";", ":", {
  nowait = true,
  desc = "enter command mode",
})
map("n", "<C-a>", "gg<S-v>G", {
  desc = "Select All",
})

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- blackhole mappings
map("n", "<C-c>", "_", {
  desc = "Blackhole",
})

if vim.g.vscode then
  require "mappings.vscode"
else
  require "mappings.neovim"
end
