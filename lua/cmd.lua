local M = {}

-- Create a custom cmd call autoflake command to remove unused imports for python files
function M.remove_unused_imports()
  local fileName = vim.api.nvim_buf_get_name(0)
  -- test if the file is a python file
  if not string.match(fileName, "%.py$") then
    return
  end

  -- test if autoflake is installed
  if vim.fn.executable "autoflake" == 0 then
    return
  end

  vim.cmd(":silent !autoflake --remove-all-unused-imports -i --ignore-init-module-imports " .. fileName, "silent")
end

vim.api.nvim_create_user_command("PyRemoveUnusedImports", "lua require'cmd'.remove_unused_imports()", {})

return M
