local function config()
  local options = {
    lsp_fallback = true,
    formatters_by_ft = {
      lua = { "stylua" },

      javascript = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      markdown = { "prettier" },
      yaml = { "prettier" },

      sh = { "shfmt" },
      fish = { "fish_indent" },

      python = { "ruff_format", "ruff_organize_imports" },
      -- Use the "*" filetype to run formatters on all filetypes.
      ["*"] = { "codespell" },
      -- Use the "_" filetype to run formatters on filetypes that don't
      -- have other formatters configured.
      ["_"] = { "trim_whitespace" },
    },
  }

  require("conform").setup(options)
end

local plugin = {
  "stevearc/conform.nvim",
  --  for users those who want auto-save conform + lazyloading!
  -- event = "BufWritePre"
  config = config,
  init = function()
    vim.keymap.set("n", "<leader>lf", "<cmd>lua require('conform').format()<cr>", {
      desc = "Format the current buffer",
    })
  end,
}

return plugin
