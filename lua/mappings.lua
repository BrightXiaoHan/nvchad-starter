local map = vim.keymap.set

function ToggleWrap()
  vim.wo.wrap = not vim.wo.wrap
end

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
  map("n", "<leader>x", "<Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')", {
    desc = "buffer close",
  })
  map("n", "<leader>w", "<Cmd>call VSCodeNotify('editor.action.toggleWordWrap')", {
    desc = "Toggle wrap",
  })
  map("n", "<A-Left>", "<Cmd>call VSCodeNotify('workbench.action.decreaseViewSize')", {
    desc = "Decrease window width",
  })
  map("n", "<A-Right>", "<Cmd>call VSCodeNotify('workbench.action.increaseViewSize')", {
    desc = "Increase window width",
  })
  map("n", "<A-Up>", "<Cmd>call VSCodeNotify('workbench.action.increaseViewSize')", {
    desc = "Increase window height",
  })
  map("n", "<A-Down>", "<Cmd>call VSCodeNotify('workbench.action.decreaseViewSize')", {
    desc = "Decrease window height",
  })
  map("n", "<leader><tab>", "<Cmd>call VSCodeNotify('workbench.action.nextEditor')", {
    desc = "Switch window",
  })
  map("n", "<leader>q", "<Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')", {
    desc = "Quit",
  })
  map("n", "<leader>c", "<Cmd>call VSCodeNotify('workbench.action.closeOtherEditors')", {
    desc = "buffer close",
  })

  -- toggle file explorer
  map("n", "<leader>e", "<Cmd>call VSCodeNotify('workbench.view.explorer')", {
    desc = "Toggle file explorer",
  })
else
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
  map("t", "<Esc>", "<C-\\><C-n>", {})
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
end
