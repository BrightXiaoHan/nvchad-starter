local function init()
  local map = vim.keymap.set
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
end

local plugin = {
  "lewis6991/gitsigns.nvim",
  event = "User FilePost",
  opts = function()
    return require "nvchad.configs.gitsigns"
  end,
  init = init,
}
return plugin
