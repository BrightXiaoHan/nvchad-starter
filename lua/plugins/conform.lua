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
-- Create a custom cmd call autoflake command to remove unused imports for python files
local function remove_unused_imports()
  local fileName = vim.api.nvim_buf_get_name(0)
  -- test if the file is a python file
  if not string.match(fileName, "%.py$") then
    return
  end

  -- test if autoflake is installed
  if vim.fn.executable "ruff" == 0 then
    return
  end

  vim.cmd(":silent !ruff check --fix --force-exclude --exit-zero --no-cache " .. fileName)
end

local plugin = {
  "stevearc/conform.nvim",
  config = config,
  init = function()
    vim.api.nvim_create_user_command("PyRemoveUnusedImports", remove_unused_imports, {})

    vim.keymap.set("n", "<leader>lf", "<cmd>lua require('conform').format()<cr>", {
      desc = "Format the current buffer",
    })
    vim.keymap.set("n", "<leader>li", "<cmd>PyRemoveUnusedImports<cr>", {
      desc = "Remove unused imports",
    })
  end,
}

return plugin
