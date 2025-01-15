local map = vim.keymap.set

-- nvchad mappings
map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

function ToggleWrap()
  vim.wo.wrap = not vim.wo.wrap
end
-- General mappings
map("n", ";", ":", {
  nowait = true,
  desc = "enter command mode",
})
map("n", "<C-a>", "gg<S-v>G", {
  desc = "Select All",
})
map("n", "<leader>w", "<cmd>lua ToggleWrap()<cr>", {
  desc = "Toggle wrap",
})
map("n", "<leader>m", "<cmd>lua vim.o.mouse = vim.o.mouse == 'a' and 'v' or 'a'<cr>", {
  desc = "Toggle mouse mode",
})
map("n", "<A-Left>", "<C-w><", {
  desc = "Decrease window width",
})
map("n", "<A-Right>", "<C-w>>", {
  desc = "Increase window width",
})
map("n", "<A-Up>", "<C-w>+", {
  desc = "Increase window height",
})
map("n", "<A-Down>", "<C-w>-", {
  desc = "Decrease window height",
})
map("n", "<leader><tab>", "<C-w>w", {
  desc = "Switch window",
})
map("n", "<leader>q", "<cmd>q<cr>", {
  desc = "Quit",
})
map("t", "<Esc>", "<C-\\><C-n>", {})

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- blackhole mappings
map("n", "<C-c>", "_", {
  desc = "Blackhole",
})

-- Custom cmd mappings
map("n", "<leader>c", function()
  local current_bufnr = vim.api.nvim_get_current_buf()

  for _, bufnr in ipairs(vim.t.bufs) do
    if bufnr ~= current_bufnr then
      require("nvchad.tabufline").close_buffer(bufnr)
    end
  end
end, { desc = "buffer close" })
map("n", "<leader>gf", "<cmd>OpenFileUnderCursor<cr>", {
  desc = "Open file under cursor",
})
