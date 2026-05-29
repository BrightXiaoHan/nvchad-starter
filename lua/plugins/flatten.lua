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
  }, --- ...
}

return plugin
