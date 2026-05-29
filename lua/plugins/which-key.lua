local plugin = {
  "folke/which-key.nvim",
  opts = {},
  config = function(_, opts)
    local wk = require "which-key"
    wk.setup(opts)
    -- register leader bindings with new spec to silence warnings
    wk.add {
      { "<leader>", group = "leader" },
    }
  end,
}

return plugin
