local plugin = {
  "mcauley-penney/visual-whitespace.nvim",
  config = true,
  init = function()
    require("visual-whitespace").setup()
  end,
}

return plugin
