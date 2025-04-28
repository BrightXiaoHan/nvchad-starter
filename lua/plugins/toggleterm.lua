-- if win32, use pwsh
-- otherwise, use fish
if vim.fn.has "win32" == 1 then
  SHELL = "pwsh"
else
  SHELL = "fish"
end

local opts = {
  shell = SHELL,
}

local plugin = {
  "akinsho/toggleterm.nvim",
  config = true,
  lazy = false,
  opts = opts,
  init = function()
    vim.keymap.set("n", "<C-\\>", "<cmd>ToggleTerm direction=horizontal<CR>", {
      desc = "Toggle horizontal term",
    })
    vim.keymap.set("t", "<C-\\>", "<cmd>ToggleTerm direction=horizontal<CR>", {
      desc = "Toggle horizontal term",
    })
    vim.keymap.set("n", "<C-`>", "<cmd>ToggleTerm direction=horizontal<CR>", {
      desc = "Toggle horizontal term",
    })
    vim.keymap.set("t", "<C-`>", "<cmd>ToggleTerm direction=horizontal<CR>", {
      desc = "Toggle horizontal term",
    })
  end,
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
