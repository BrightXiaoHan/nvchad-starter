require "nvchad.mappings"

local map = vim.keymap.set

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
map("n", "<C-Left>", "<C-w><", {
  desc = "",
})
map("n", "<C-Right>", "<C-w>>", {
  desc = "",
})
map("n", "<A-Up>", "<C-w>+", {
  desc = "",
})
map("n", "<A-Down>", "<C-w>-", {
  desc = "",
})
map("n", "<leader><tab>", "<C-w>w", {
  desc = "",
})
map("n", "<C-p>", ":Telescope find_files<CR>", {
  desc = "Find file",
})
map("n", "<C-f>", ":Telescope live_grep<CR>", {
  desc = "Fuzzy find",
})
map("n", "<leader>q", "<cmd>q<cr>", {
  desc = "Quit",
})
map("n", "<leader>o", "<cmd>AerialToggle<cr>", {
  desc = "Outline",
})
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", {
  desc = "Explorer",
})
map("n", "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<cr>", {
  desc = "Find",
})
map("n", "<C-\\>", function()
  require("nvterm.terminal").toggle "horizontal"
end, {
  desc = "Toggle horizontal term",
})
map("t", "<C-\\>", function()
  require("nvterm.terminal").toggle "horizontal"
end, {
  desc = "Toggle horizontal term",
})
map("t", "<Esc>", "<C-\\><C-n>", {})

-- Plugin mappings

-- Copilot mappings
map("i", "<C-i>", function()
  vim.fn.feedkeys(vim.fn["copilot#Accept"](), "")
end, {
  replace_keycodes = true,
  nowait = true,
  silent = true,
  expr = true,
  noremap = true,
})

-- Lsp mappings
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", {
  desc = "Go to definition",
})
map("n", "<leader>lf", function()
  require("conform").format()
end, {
  desc = "formatting",
})
map("n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", {
  desc = "Rename",
})
map("n", "<leader>ld", "<cmd>lua vim.diagnostic.open_float(0, {scope='line'})<CR>", {
  desc = "Line diagnostics",
})
map("n", "<leader>lp", "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>", {
  desc = "Previous diagnostic",
})
map("n", "<leader>ln", "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>", {
  desc = "Next diagnostic",
})
map("n", "<C-LeftMouse>", "<cmd>lua vim.lsp.buf.definition()<cr>", {
  desc = "Go to definition",
})
map("n", "<C-RightMouse>", "<cmd>lua vim.lsp.buf.references()<cr>", {
  desc = "Go to references",
})
map("n", "<leader>li", "<cmd>PyRemoveUnusedImports<cr>", {
  desc = "Remove unused imports",
})

-- gitsigns mappings
map("n", "]c", function()
  if vim.wo.diff then
    return "[c"
  end
  vim.schedule(function()
    require("gitsigns").prev_hunk()
  end)
  return "<Ignore>"
end, {
  expr = true,
})
map("n", "[c", function()
  if vim.wo.diff then
    return "]c"
  end
  vim.schedule(function()
    require("gitsigns").next_hunk()
  end)
  return "<Ignore>"
end, {
  expr = true,
})
map("n", "<leader>gs", "<cmd>lua require'gitsigns'.stage_hunk()<CR>", {
  desc = "Stage hunk",
})
map("n", "<leader>gr", "<cmd>lua require'gitsigns'.reset_hunk()<CR>", {
  desc = "Reset hunk",
})
map("n", "<leader>gS", "<cmd>lua require'gitsigns'.stage_buffer()<CR>", {
  desc = "Stage buffer",
})
map("n", "<leader>gu", "<cmd>lua require'gitsigns'.undo_stage_hunk()<CR>", {
  desc = "Undo stage hunk",
})
map("n", "<leader>gR", "<cmd>lua require'gitsigns'.reset_buffer()<CR>", {
  desc = "Reset buffer",
})
map("n", "<leader>gp", "<cmd>lua require'gitsigns'.preview_hunk()<CR>", {
  desc = "Preview hunk",
})
map("n", "<leader>gb", "<cmd>lua require'gitsigns'.blame_line()<CR>", {
  desc = "Blame line",
})
map("n", "<leader>gt", "<cmd>lua require'gitsigns'.toggle_current_line_blame()<CR>", {
  desc = "Toggle current line blame",
})
map("n", "<leader>gd", "<cmd>lua require'gitsigns'.diffthis()<CR>", {
  desc = "Diff this",
})
map("n", "<leader>gD", "<cmd>lua require'gitsigns'.diffthis()<CR>", {
  desc = "Diff this (vertical split)",
})

-- spectre mappings
map("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', {
  desc = "Toggle Spectre",
})
map("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
  desc = "Search current word",
})
map("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
  desc = "Search in current file",
})
