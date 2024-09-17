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
  -- nil check
  if not node then
    return
  end

  if node.type == "directory" then
    api.node.open.preview()
    return
  end

  -- if current node is a file, open preview it and switch to the window
  api.node.open.preview()
  vim.cmd "wincmd l"
end

function M.nvim_tree_tsz()
  if vim.env.SSH_TTY == nil then
    return
  end
  local api = require "nvim-tree.api"
  local lib = require "nvim-tree.lib"
  -- if current node is a folder, open it
  local node = lib.get_node_at_cursor()
  -- nil check
  if not node then
    return
  end
  -- get absolute path of the current node
  local path = node.absolute_path
  -- run tsz command
  vim.cmd("!tsz -q -y -d -b " .. path)
  -- refresh the tree
  api.tree.reload()
end

function M.nvim_tree_trz()
  if vim.env.SSH_TTY == nil then
    return
  end
  local api = require "nvim-tree.api"
  local lib = require "nvim-tree.lib"
  -- if current node is a folder, open it
  local node = lib.get_node_at_cursor()
  -- nil check
  if not node then
    return
  end
  -- get absolute path of the current node
  local path = node.absolute_path
  -- if current node is a file, get the parent directory of the file
  if node.type == "file" then
    path = vim.fn.fnamemodify(path, ":h")
  end
  -- run trz command
  vim.cmd("!trz -q -y -b " .. path)
  -- refresh the tree
  api.tree.reload()
end

local function osc52_copy(text)
  local function set_clipboard(lines)
    local data = table.concat(lines, "\n")
    local encoded = vim.fn.system("base64", data):gsub("\n", "")
    local esc = string.format("\x1b]52;c;%s\x07", encoded)

    if vim.fn.exists "$TMUX" == 1 then
      esc = string.format("\x1bPtmux;\x1b%s\x1b\\", esc)
    end

    io.stdout:write(esc)
    io.stdout:flush()
  end

  if type(text) == "string" then
    set_clipboard { text }
  elseif type(text) == "table" then
    set_clipboard(text)
  else
    error("Unsupported text type: " .. type(text))
  end
end

-- Function to copy the current selection
function copy_selection()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    vim.cmd "normal! y"
  end
  local text = vim.fn.getreg '"'
  osc52_copy(text)
end

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.env.TMUX then
      copy_selection()
    elseif vim.env.SSH_TTY then
      vim.highlight.on_yank()
      local version = vim.version()
      -- if version is less than 0.10.0
      if version.major == 0 and version.minor < 10 then
        return
      end
      local copy_to_unnamedplus = require("vim.ui.clipboard.osc52").copy "+"
      copy_to_unnamedplus(vim.v.event.regcontents)
      local copy_to_unnamed = require("vim.ui.clipboard.osc52").copy "*"
      copy_to_unnamed(vim.v.event.regcontents)
    end
  end,
})

-- Expose the function globally so it can be called from Neovim command line
_G.osc52_copy = osc52_copy

return M
