local plugin = {
  {
    "willothy/flatten.nvim",
    opts = function()
      return {
        window = {
          open = "tab",
        },
      }
    end,
  },
}

return plugin
