-- Shared window helpers for classifying and targeting "normal" editing
-- windows, so sidebars (agent term, nvim-tree) and other special windows are
-- treated consistently across modules.
local M = {}

---Whether a window is a valid target for loading a file: not floating, not
---winfixbuf-locked, not the nvim-tree sidebar, and not a terminal/help/
---quickfix/prompt buffer. nofile buffers (e.g. the NvDash dashboard) count
---as valid targets so opening a file replaces the dashboard.
---@param win integer
---@return boolean
function M.is_editable(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local config = vim.api.nvim_win_get_config(win)
  if config.relative ~= "" or config.external then
    return false
  end

  -- skip windows locked to their buffer (e.g. agent term sidebar)
  if vim.wo[win].winfixbuf then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local buftype = vim.bo[buf].buftype
  if buftype == "terminal"
    or buftype == "help"
    or buftype == "prompt"
    or buftype == "quickfix"
  then
    return false
  end

  if vim.bo[buf].filetype == "NvimTree" then
    return false
  end

  return true
end

---Whether the tabpage has at least one editable window.
---@param tabpage integer? default current tabpage
---@return boolean
function M.has_editable(tabpage)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage or 0)) do
    if M.is_editable(win) then
      return true
    end
  end
  return false
end

---Make the current window editable: if it isn't, jump to the first editable
---window in the tab; create one if none exists.
function M.focus_editable()
  if M.is_editable(vim.api.nvim_get_current_win()) then
    return
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if M.is_editable(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  vim.cmd "belowright vsplit"
end

return M
