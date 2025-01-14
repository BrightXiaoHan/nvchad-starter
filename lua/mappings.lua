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
map("n", "<leader>q", "<cmd>q<cr>", {
  desc = "Quit",
})
map("t", "<Esc>", "<C-\\><C-n>", {})

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

-- Telescope mappings
map("n", "<C-p>", ":Telescope find_files<CR>", {
  desc = "Find file",
})
map("n", "<C-f>", ":Telescope live_grep<CR>", {
  desc = "Fuzzy find",
})
map("n", "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<cr>", {
  desc = "Find",
})

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

if vim.env.SSH_TTY then
  vim.keymap.set(
    "n",
    "<leader>tr",
    require("nvim-trzsz").nvim_tree_trz,
    { noremap = true, silent = true, desc = "Trz: upload file" }
  )

  vim.keymap.set(
    "n",
    "<leader>ts",
    require("nvim-trzsz").nvim_tree_tsz,
    { noremap = true, silent = true, desc = "Tsz: download file" }
  )
end
