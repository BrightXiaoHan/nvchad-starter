-- Mappings module init file
-- This file is loaded when require("mappings") is called

local map = vim.keymap.set

-- General mappings (available in both VSCode and Neovim)
-- nvchad mappings
map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

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