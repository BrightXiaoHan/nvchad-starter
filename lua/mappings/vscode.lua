-- VSCode-Neovim compatible key mappings
local vscode = require "vscode"
local map = vim.keymap.set

-- Switch window/editor
map("n", "<leader><tab>", function()
  vscode.action "workbench.action.navigateEditorGroups"
end, { desc = "Switch editor group" })

map("n", "<leader>q", function()
  vscode.action "workbench.action.closeActiveEditor"
end, { desc = "Close active editor" })

-- Close other editors
map("n", "<leader>c", function()
  vscode.action "workbench.action.closeOtherEditors"
end, { desc = "Close other editors" })
-- Open file under cursor
map("n", "<leader>gf", function()
  vscode.action "editor.action.revealDefinition"
end, { desc = "Open file under cursor" })

-- plugins mappings alternatives
map("n", "<leader>e", function()
  vscode.action "workbench.view.explorer"
end, { desc = "Toggle file explorer" })

-- git mappings
map("n", "<leader>gr", function()
  vscode.action "git.revertSelectedRanges"
end, { desc = "Revert" })

-- Map <space>gR to Git revert entire file
vim.keymap.set("n", "<space>gR", function()
  vscode.action "git.revertAllChanges"
end, { desc = "Git revert entire file" })