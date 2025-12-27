local map = vim.keymap.set

-- ToggleWrap function used by Neovim mappings
function ToggleWrap()
  vim.wo.wrap = not vim.wo.wrap
end
-- General mappings (available in both VSCode and Neovim)
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
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Custom cmd mappings
map("n", "<leader>c", function()
  local current_bufnr = vim.api.nvim_get_current_buf()

  for _, bufnr in ipairs(vim.t.bufs) do
    if bufnr ~= current_bufnr then
      require("nvchad.tabufline").close_buffer(bufnr)
    end
  end
end, { desc = "buffer close" })
