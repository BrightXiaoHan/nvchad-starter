local M = {}

local uv = vim.uv or vim.loop
local timer = uv.new_timer()
local on_key_ns = vim.api.nvim_create_namespace "local_better_escape"

M.waiting = false

local settings = {
  timeout = vim.o.timeoutlen,
  mappings = {
    i = {
      j = {
        k = "<Esc>",
        j = "<Esc>",
      },
    },
    c = {
      j = {
        k = "<C-c>",
        j = "<C-c>",
      },
    },
    t = {
      j = {
        k = "<C-\\><C-n>",
      },
    },
    v = {
      j = {
        k = "<Esc>",
      },
    },
    s = {
      j = {
        k = "<Esc>",
      },
    },
  },
}

local mapped_keys = {}
local recorded_key
local recorded_mode
local recorded_modified

local undo_key = {
  i = "<BS>",
  c = "<BS>",
  t = "<BS>",
}

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

local function clear_recorded()
  M.waiting = false
  recorded_key = nil
  recorded_mode = nil
  recorded_modified = nil
end

local function record_key(mode, key)
  if timer:is_active() then
    timer:stop()
  end

  recorded_key = key
  recorded_mode = mode
  recorded_modified = vim.bo.modified
  M.waiting = true

  timer:start(settings.timeout, 0, vim.schedule_wrap(clear_recorded))
end

local function escape(mode, mapping)
  local modified = recorded_modified and "" or "no"
  local keys = (undo_key[mode] or "") .. ("<cmd>setlocal %smodified<cr>"):format(modified)

  if type(mapping) == "function" then
    keys = keys .. (mapping() or "")
  else
    keys = keys .. mapping
  end

  clear_recorded()
  vim.api.nvim_feedkeys(termcodes(keys), "in", false)
  return ""
end

local function mode_keys(mode_mappings)
  local keys = {}

  for first_key, second_keys in pairs(mode_mappings) do
    keys[first_key] = true
    for second_key in pairs(second_keys) do
      keys[second_key] = true
    end
  end

  return keys
end

local function unmap_keys()
  for _, item in ipairs(mapped_keys) do
    pcall(vim.keymap.del, item.mode, item.key)
  end
  mapped_keys = {}
end

local function sequence_mapping(mode, key)
  if recorded_mode ~= mode or not recorded_key then
    return nil
  end

  local first_key = settings.mappings[mode] and settings.mappings[mode][recorded_key]
  return first_key and first_key[key] or nil
end

local function map_key(mode, key)
  vim.keymap.set(mode, key, function()
    local mode_mappings = settings.mappings[mode] or {}
    local mapping = sequence_mapping(mode, key)

    if mapping then
      return escape(mode, mapping)
    end

    if mode_mappings[key] then
      record_key(mode, key)
    else
      clear_recorded()
    end

    return key
  end, {
    expr = true,
    noremap = true,
    desc = "Local better escape",
  })

  mapped_keys[#mapped_keys + 1] = {
    mode = mode,
    key = key,
  }
end

local function map_keys()
  for mode, mode_mappings in pairs(settings.mappings) do
    for key in pairs(mode_keys(mode_mappings)) do
      map_key(mode, key)
    end
  end
end

local function is_expected_key(typed)
  if not recorded_mode or not recorded_key then
    return false
  end

  if typed == recorded_key then
    return true
  end

  return sequence_mapping(recorded_mode, typed) ~= nil
end

local function watch_unmapped_keys()
  pcall(vim.on_key, nil, on_key_ns)
  vim.on_key(function(_, typed)
    if typed == "" or is_expected_key(typed) then
      return
    end

    clear_recorded()
  end, on_key_ns)
end

function M.setup(opts)
  settings = vim.tbl_deep_extend("force", settings, opts or {})

  unmap_keys()
  map_keys()
  watch_unmapped_keys()
end

return M
