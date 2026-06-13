local M = {}

local function buffer_has_formatter(bufnr)
  local ok, clients = pcall(vim.lsp.get_clients, {
    bufnr = bufnr,
    method = "textDocument/formatting",
  })

  return ok and #clients > 0
end

local function format_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if not buffer_has_formatter(bufnr) then
    vim.notify("No LSP formatter attached to current buffer", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf.format {
    bufnr = bufnr,
    async = true,
  }
end

local function remove_unused_imports()
  local file = vim.api.nvim_buf_get_name(0)
  if not file:match "%.py$" then
    return
  end

  if vim.fn.executable "ruff" == 0 then
    vim.notify("ruff is not installed", vim.log.levels.WARN)
    return
  end

  vim.system({
    "ruff",
    "check",
    "--fix",
    "--force-exclude",
    "--exit-zero",
    "--no-cache",
    file,
  }, {}, function()
    vim.schedule(function()
      vim.cmd "checktime"
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("PyRemoveUnusedImports", remove_unused_imports, {})

  vim.keymap.set("n", "<leader>lf", format_buffer, {
    desc = "Format the current buffer",
  })

  vim.keymap.set("n", "<leader>li", "<cmd>PyRemoveUnusedImports<cr>", {
    desc = "Remove unused imports",
  })
end

return M
