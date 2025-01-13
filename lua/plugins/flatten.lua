local plugin = {
  {
    "willothy/flatten.nvim",
    -- config = true,
    -- or pass configuration with
    opts = function()
      return {
        window = {
          open = "tab",
        },
      }
    end,
    -- Ensure that it runs first to minimize delay when opening file from terminal
    lazy = false,
    priority = 1001,
  }, --- ...
}

return plugin
