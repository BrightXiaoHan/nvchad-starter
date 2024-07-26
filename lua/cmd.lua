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

function M.nvim_tree_open_preview()
  local api = require "nvim-tree.api"
  local lib = require "nvim-tree.lib"
  -- if current node is a folder, open it
  local node = lib.get_node_at_cursor()
  if node.type == "directory" then
    api.node.open.preview()
    return
  end

  -- if current node is a file, open preview it and switch to the window
  api.node.open.preview()
  vim.cmd "wincmd l"
end

return M
