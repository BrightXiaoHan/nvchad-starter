local plugin = {
  "Exafunction/windsurf.vim",
  event = "BufEnter",
  cond = function()
    return not vim.g.vscode
  end,
  event = "VeryLazy",
  config = function()
    -- Change '<C-g>' here to any keycode you like.
    vim.keymap.set("i", "<Tab>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true, silent = true })
  end,
}

return plugin
