local M = {}

-- Create a custom cmd call autoflake command to remove unused imports for python files
function M.remove_unused_imports()
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

vim.api.nvim_create_user_command("PyRemoveUnusedImports", "lua require'cmd'.remove_unused_imports()", {})

function M.nvim_tree_open_preview()
  local api = require "nvim-tree.api"
  -- if current node is a folder, open it
  local node = api.tree.get_node_under_cursor()
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
  -- if current node is a folder, open it
  local node = api.tree.get_node_under_cursor()
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
  -- if current node is a folder, open it
  local node = api.tree.get_node_under_cursor()
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
local function copy_selection()
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

-- Lua function to open file under cursor in a specific window
function M.OpenFileUnderCursor()
  -- Get all windows in the current tab
  local windows = vim.api.nvim_tabpage_list_wins(0)
  local selected_window

  for _, win in ipairs(windows) do
    -- Get the buffer associated with the window
    local buf = vim.api.nvim_win_get_buf(win)

    -- Get the file type of the buffer
    local filetype = vim.bo[buf].filetype

    -- Check if the window is not a terminal or nvim-tree window
    if filetype ~= "NvimTree" and filetype ~= "toggleterm" then
      selected_window = win
      break
    end
  end

  if not selected_window then
    -- alert
    vim.api.nvim_err_writeln "No suitable window found"
    return
  end

  local file = vim.fn.expand "<cfile>" -- Get file under cursor
  -- Check if the file exists
  if vim.fn.filereadable(file) == 0 then
    -- alert
    vim.api.nvim_err_writeln("File does not exist: " .. file)
    return
  end

  -- Get absolute path of the file
  local absolute_path = vim.fn.fnamemodify(file, ":p")

  -- Create or get buffer for the file
  local bufnr = vim.fn.bufadd(absolute_path)
  vim.fn.bufload(bufnr)

  -- Set the buffer in the selected window
  vim.api.nvim_win_set_buf(selected_window, bufnr)
end

vim.api.nvim_create_user_command("OpenFileUnderCursor", "lua require'cmd'.OpenFileUnderCursor()", {})

-- Expose the function globally so it can be called from Neovim command line
_G.osc52_copy = osc52_copy

return M
