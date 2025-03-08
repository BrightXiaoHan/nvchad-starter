local map = vim.keymap.set

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