local plugin = {
  "Exafunction/windsurf.vim",
  event = "BufEnter",
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
