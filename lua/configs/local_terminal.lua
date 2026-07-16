local api = vim.api
local fn = vim.fn
local window = require "configs.window"
local M = {}

-- if win32, use pwsh
-- otherwise, use fish
local SHELL
if vim.fn.has "win32" == 1 then
  SHELL = "pwsh"
else
  SHELL = "fish"
end

local highlights = {
  NormalFloat = {
    guibg = "#0d1117",
  },
  FloatBorder = {
    guibg = "#0d1117",
    guifg = "#0d1117",
  },
}

local hl_groups = {
  normal = "LocalTermNormal",
  border = "LocalTermBorder",
}

local augroup = api.nvim_create_augroup("LocalToggleTerm", { clear = true })

local function nvim_is_exiting()
  local exiting = vim.v.exiting
  -- v:exiting is the numeric exit code while Neovim is leaving; 0 still
  -- means "exiting", so only v:null/nil should count as not exiting.
  return exiting ~= nil and exiting ~= vim.NIL
end

local function win_in_tabpage(win, tabpage)
  if not win or not api.nvim_win_is_valid(win) then
    return false
  end

  for _, tab_win in ipairs(api.nvim_tabpage_list_wins(tabpage or 0)) do
    if tab_win == win then
      return true
    end
  end
  return false
end

local function apply_highlights()
  local normal = highlights.NormalFloat or {}
  local border = highlights.FloatBorder or {}

  api.nvim_set_hl(0, hl_groups.normal, { bg = normal.guibg })
  api.nvim_set_hl(0, hl_groups.border, { bg = border.guibg, fg = border.guifg })
end

local function resolve_size(value, term)
  if value == nil then
    return nil
  end
  if type(value) == "number" then
    return value
  end
  if type(value) == "function" then
    return value(term)
  end
  return nil
end

local function float_config(term)
  local opts = term.float_opts or {}
  local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20)))
  local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))

  width = resolve_size(opts.width, term) or width
  height = resolve_size(opts.height, term) or height

  local row = math.ceil(vim.o.lines - height) * 0.5 - 1
  local col = math.ceil(vim.o.columns - width) * 0.5 - 1

  row = resolve_size(opts.row, term) or row
  col = resolve_size(opts.col, term) or col

  return {
    relative = opts.relative or "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "single",
    zindex = opts.zindex,
  }
end

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(opts)
  local term = setmetatable({}, Terminal)
  term.id = opts.id
  term.cmd = opts.cmd
  term.mode = opts.mode or "float"
  term.float_opts = opts.float_opts or {}
  term.close_on_exit = opts.close_on_exit ~= false
  term.buf = nil
  term.win = nil
  term.job = nil
  term.autocmds = false
  term.resize_autocmd = nil
  term.termclose_autocmd = nil
  term.cleanup_scheduled = false
  return term
end

function Terminal:_buf_valid()
  return self.buf and api.nvim_buf_is_valid(self.buf)
end

function Terminal:_win_valid()
  return self.win and api.nvim_win_is_valid(self.win)
end

function Terminal:_job_running()
  if not self.job then
    return false
  end
  return fn.jobwait({ self.job }, 0)[1] == -1
end

function Terminal:is_open(tabpage)
  if not self:_win_valid() then
    return false
  end
  return tabpage == nil or win_in_tabpage(self.win, tabpage)
end

function Terminal:_ensure_buf()
  if self:_buf_valid() then
    return self.buf
  end
  self.buf = api.nvim_create_buf(false, false)
  vim.bo[self.buf].bufhidden = "hide"
  vim.bo[self.buf].swapfile = false
  vim.bo[self.buf].buflisted = false
  return self.buf
end

function Terminal:_apply_buf_options()
  if not self:_buf_valid() then
    return
  end
  vim.bo[self.buf].filetype = "toggleterm"
  vim.b[self.buf].toggle_number = self.id
end

function Terminal:_apply_win_options()
  if not self:_win_valid() then
    return
  end
  vim.wo[self.win].number = false
  vim.wo[self.win].relativenumber = false
  vim.wo[self.win].scrolloff = 0
  vim.wo[self.win].sidescrolloff = 0
  if self.mode == "split" then
    -- lock the buffer so file opens never overwrite this terminal window
    vim.wo[self.win].winfixbuf = true
  else
    vim.wo[self.win].winhl = "NormalFloat:" .. hl_groups.normal .. ",FloatBorder:" .. hl_groups.border
    if self.float_opts.winblend ~= nil then
      vim.wo[self.win].winblend = self.float_opts.winblend
    end
  end
end

function Terminal:_close_win()
  if self:_win_valid() then
    local ok = pcall(api.nvim_win_close, self.win, true)
    if not ok and self:_win_valid() then
      return false
    end
  end
  self.win = nil
  return true
end

function Terminal:_delete_buf()
  if self:_buf_valid() then
    pcall(api.nvim_buf_delete, self.buf, { force = true })
  end
  self.buf = nil
  self.win = nil
end

function Terminal:_replace_buf()
  local win = self:_win_valid() and self.win or nil
  self:_clear_autocmds()
  self:_delete_buf()
  local buf = self:_ensure_buf()
  if win and api.nvim_win_is_valid(win) then
    self.win = win
    api.nvim_win_set_buf(win, buf)
  end
  return buf
end

function Terminal:_clear_autocmds()
  if self.resize_autocmd then
    pcall(api.nvim_del_autocmd, self.resize_autocmd)
    self.resize_autocmd = nil
  end
  if self.termclose_autocmd then
    pcall(api.nvim_del_autocmd, self.termclose_autocmd)
    self.termclose_autocmd = nil
  end
  self.autocmds = false
end

function Terminal:_schedule_exit_cleanup()
  self.job = nil
  if nvim_is_exiting() then
    return
  end
  if self.cleanup_scheduled then
    return
  end
  self.cleanup_scheduled = true

  local ok = pcall(vim.schedule, function()
    self.cleanup_scheduled = false

    if nvim_is_exiting() then
      return
    end

    if self.close_on_exit then
      self:_close_win()
      self:_delete_buf()
    end
    self:_clear_autocmds()
  end)
  if not ok then
    self.cleanup_scheduled = false
  end
end

function Terminal:_register_autocmds()
  if self.autocmds or not self:_buf_valid() then
    return
  end
  self.autocmds = true

  if self.mode == "float" then
    self.resize_autocmd = api.nvim_create_autocmd("VimResized", {
      group = augroup,
      callback = function()
        if self:is_open() then
          api.nvim_win_set_config(self.win, float_config(self))
        end
      end,
    })
  end

  self.termclose_autocmd = api.nvim_create_autocmd("TermClose", {
    group = augroup,
    buffer = self.buf,
    callback = function()
      self:_schedule_exit_cleanup()
    end,
  })
end

function Terminal:_start_job()
  if self:_job_running() then
    return
  end
  if self:_buf_valid() then
    local ok, job_id = pcall(api.nvim_buf_get_var, self.buf, "terminal_job_id")
    if ok and job_id and fn.jobwait({ job_id }, 0)[1] == -1 then
      self.job = job_id
      return
    end

    -- A terminal buffer whose job has already exited cannot reliably be reused
    -- for termopen(); replace stale adopted/reloaded buffers before restarting.
    if vim.bo[self.buf].buftype == "terminal" then
      self:_replace_buf()
    end
  end

  local cmd = self.cmd or SHELL or vim.o.shell
  self.job = fn.termopen(cmd, {
    on_exit = function()
      self:_schedule_exit_cleanup()
    end,
  })
end

function Terminal:open()
  if self.mode == "split" then
    self:_open_split()
  else
    self:_open_float()
  end
end

function Terminal:_open_split()
  local buf = self:_ensure_buf()
  vim.cmd "topleft vsplit"
  self.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(self.win, buf)
  self:_apply_win_options()
  self:_start_job()
  self:_apply_buf_options()
  self:_register_autocmds()
  if api.nvim_get_current_win() == self.win then
    vim.cmd "startinsert"
  end
end

function Terminal:_open_float()
  local buf = self:_ensure_buf()
  local win = api.nvim_open_win(buf, true, float_config(self))
  self.win = win
  self:_apply_win_options()
  self:_start_job()
  self:_apply_buf_options()
  self:_register_autocmds()
  if api.nvim_get_current_win() == win then
    vim.cmd "startinsert"
  end
end

function Terminal:close()
  self:_close_win()
end

function Terminal:toggle()
  if self:is_open() then
    self:close()
  else
    self:open()
  end
end

function Terminal:shutdown()
  if self:_job_running() then
    pcall(fn.jobstop, self.job)
  end
  self.job = nil
  self:_close_win()
  self:_delete_buf()
  self:_clear_autocmds()
end

-- AI terminals state management (mutually exclusive)
local ai_terms = {}

local function hide_other_ai_terms(current_name)
  for name, term in pairs(ai_terms) do
    if name ~= current_name and term and term:is_open() then
      term:close()
    end
  end
end

local function find_visible_win_for_buf(buf)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf then
      return win
    end
  end

  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function terminal_job_running(buf)
  local ok, job_id = pcall(api.nvim_buf_get_var, buf, "terminal_job_id")
  if ok and job_id and fn.jobwait({ job_id }, 0)[1] == -1 then
    return true, job_id
  end
  return false, nil
end

local function find_ai_term_buf(id)
  local visible_buf, running_buf, fallback_buf

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "toggleterm" then
      local ok, toggle_number = pcall(api.nvim_buf_get_var, buf, "toggle_number")
      if ok and toggle_number == id then
        local visible = find_visible_win_for_buf(buf) ~= nil
        local running = terminal_job_running(buf)

        if visible and running then
          return buf
        elseif visible and not visible_buf then
          visible_buf = buf
        elseif running and not running_buf then
          running_buf = buf
        end

        fallback_buf = fallback_buf or buf
      end
    end
  end

  return visible_buf or running_buf or fallback_buf
end

local function adopt_existing_ai_term(term)
  local buf = find_ai_term_buf(term.id)
  if not buf then
    return
  end

  term.buf = buf
  term.win = find_visible_win_for_buf(buf)

  local running, job_id = terminal_job_running(buf)
  if running then
    term.job = job_id
  end

  term:_apply_buf_options()
  term:_apply_win_options()
  term:_register_autocmds()
end

local function get_or_create_ai_term(name, cmd, id)
  local term = ai_terms[name]

  if not term then
    term = Terminal:new {
      cmd = cmd,
      close_on_exit = true,
      id = id,
      mode = "split",
    }
    adopt_existing_ai_term(term)
    ai_terms[name] = term
  end
  return term
end

local function make_ai_toggle(name, cmd, id)
  return function()
    local term = get_or_create_ai_term(name, cmd, id)

    if term:is_open() then
      term:close()
      return
    end

    hide_other_ai_terms(name)
    term:open()
  end
end

local function make_float_bottom_toggle()
  local bottom_term = nil

  return function()
    if not bottom_term then
      bottom_term = Terminal:new {
        cmd = SHELL,
        id = 1,
        float_opts = {
          border = "none",
          width = function()
            return vim.o.columns
          end,
          height = function()
            return math.floor(vim.o.lines * 2 / 3)
          end,
          col = 0,
          row = function()
            local height = math.floor(vim.o.lines * 2 / 3)
            return vim.o.lines - height
          end,
        },
      }
    end
    bottom_term:toggle()
  end
end

local function stop_terminal_jobs()
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
      local ok, job_id = pcall(api.nvim_buf_get_var, buf, "terminal_job_id")
      if ok and job_id and fn.jobwait({ job_id }, 0)[1] == -1 then
        pcall(fn.jobstop, job_id)
      end
    end
  end
end

local function clean_dashboard_buf(buf, win)
  if not buf or not api.nvim_buf_is_valid(buf) then
    return
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "nvdash"

  vim.g.nvdash_buf = buf
  vim.g.nvdash_displayed = true

  if win and api.nvim_win_is_valid(win) then
    vim.g.nvdash_win = win
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].cursorline = false
    vim.wo[win].winfixbuf = false
  end

  api.nvim_create_autocmd("BufWinLeave", {
    group = augroup,
    buffer = buf,
    once = true,
    callback = function()
      vim.g.nvdash_displayed = false
    end,
  })
end

local function has_sidebar_window()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_is_valid(win) and not window.is_editable(win) then
      local config = api.nvim_win_get_config(win)
      if config.relative == "" and not config.external then
        return true
      end
    end
  end
  return false
end

-- Recreate a central window after the last editable one closes. Instead of a
-- blank buffer, render the NvDash startup page so it matches startup.
local function open_dashboard()
  local tree_win
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_is_valid(win) and vim.bo[api.nvim_win_get_buf(win)].filetype == "NvimTree" then
      tree_win = win
      break
    end
  end

  if tree_win then
    -- nvim-tree is on the right: open the new window to its left
    api.nvim_set_current_win(tree_win)
    vim.cmd "leftabove vnew"
  else
    -- only a left sidebar (agent term): open on the far right
    vim.cmd "botright vnew"
  end

  local dash_win = api.nvim_get_current_win()
  vim.wo[dash_win].winfixbuf = false

  -- nvchad.nvdash.open() creates its own buffer and shows it in the current
  -- window; delete the throwaway buffer created by vnew. NvDash may fail in a
  -- very narrow split while moving the cursor to virtual text; keep the partial
  -- buffer recognizable as a dashboard so quit_cascade can close/quit cleanly.
  local scratch = api.nvim_get_current_buf()
  local ok = pcall(function()
    require("nvchad.nvdash").open()
  end)

  local current = api.nvim_get_current_buf()
  if not ok then
    if current == scratch then
      current = api.nvim_create_buf(false, true)
      api.nvim_win_set_buf(dash_win, current)
    end
    clean_dashboard_buf(current, dash_win)
  end

  if api.nvim_buf_is_valid(scratch) and scratch ~= current then
    pcall(api.nvim_buf_delete, scratch, { force = true })
  end
end

-- window classifiers used by the <leader>q quit cascade
local function win_filetype(win)
  return vim.bo[api.nvim_win_get_buf(win)].filetype
end

local function is_file_window(win)
  if not window.is_editable(win) then
    return false
  end

  local buf = api.nvim_win_get_buf(win)
  -- A "real file" should be a normal buffer. This excludes NvDash and partial
  -- nofile dashboards left by narrow-window render failures.
  return vim.bo[buf].buftype == "" and win_filetype(win) ~= "nvdash"
end

local function find_window(pred)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_is_valid(win) and pred(win) then
      return win
    end
  end
end

local function editable_windows()
  local wins = {}
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if window.is_editable(win) then
      wins[#wins + 1] = win
    end
  end
  return wins
end

local function close_tab_or_quit()
  if fn.tabpagenr "$" > 1 then
    vim.cmd "tabclose"
  else
    vim.cmd "qa"
  end
end

-- Cascading quit bound to <leader>q:
--   1. multiple normal/editable windows, including NvDash -> close current normal split
--   2. a single real file/edit window is open              -> replace it with NvDash
--   3. sidebars remain                                     -> close nvim-tree, then the agent term
--   4. only the dashboard / nothing left                   -> close tab, or exit if last tab
function M.quit_cascade()
  local cur = api.nvim_get_current_win()
  local edit_wins = editable_windows()
  if #edit_wins == 0 then
    close_tab_or_quit()
    return
  end

  if #edit_wins > 1 then
    local target = window.is_editable(cur) and cur
    if not target then
      target = find_window(function(w)
        return window.is_editable(w) and win_filetype(w) == "nvdash"
      end) or edit_wins[#edit_wins]
    end

    pcall(api.nvim_win_close, target, false)
    return
  end

  if find_window(is_file_window) then
    local target = is_file_window(cur) and cur or find_window(is_file_window)
    if target then
      api.nvim_set_current_win(target)
      local ok = pcall(function()
        require("nvchad.nvdash").open()
      end)
      if not ok then
        clean_dashboard_buf(api.nvim_get_current_buf(), api.nvim_get_current_win())
      end
    end
    return
  end

  local tree_win = find_window(function(w)
    return win_filetype(w) == "NvimTree"
  end)
  local pi_term = get_or_create_ai_term("pi", "pi", 95)

  if tree_win or pi_term:is_open(0) then
    if tree_win then
      pcall(api.nvim_win_close, tree_win, false)
    end
    if pi_term and pi_term:is_open(0) then
      pi_term:close()
    end
    return
  end

  close_tab_or_quit()
end

function M.setup()
  if vim.g.vscode then
    return
  end

  apply_highlights()

  local toggle_tab = make_float_bottom_toggle()
  vim.keymap.set("n", "<C-\\>", toggle_tab, {
    desc = "Toggle tab term",
  })
  vim.keymap.set("t", "<C-\\>", toggle_tab, {
    desc = "Toggle tab term",
  })
  vim.keymap.set("n", "<C-`>", toggle_tab, {
    desc = "Toggle tab term",
  })
  vim.keymap.set("t", "<C-`>", toggle_tab, {
    desc = "Toggle tab term",
  })

  local toggle_pi = make_ai_toggle("pi", "pi", 95)

  vim.keymap.set({ "n", "t" }, "<A-p>", toggle_pi, {
    desc = "Toggle Pi terminal",
  })

  api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = stop_terminal_jobs,
  })

  -- Keep at least one normal editing window: closing the last editable window
  -- (leaving only sidebars like the agent term / nvim-tree) recreates one.
  local dashboard_restore_scheduled = false
  api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function()
      if dashboard_restore_scheduled then
        return
      end
      dashboard_restore_scheduled = true

      vim.schedule(function()
        dashboard_restore_scheduled = false

        if nvim_is_exiting() then
          return
        end
        if window.has_editable(0) or not has_sidebar_window() then
          return
        end

        pcall(open_dashboard)
      end)
    end,
  })
end

return M
