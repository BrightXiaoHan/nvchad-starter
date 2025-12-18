local M = {}

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
    -- Skip expensive clipboard sync for delete/change operations; only run on actual yanks
    local event = vim.v.event
    if not event or event.operator ~= "y" then
      return
    end

    if vim.env.SSH_TTY and vim.env.TMUX then
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
