local M = {}

local uv = vim.uv or vim.loop
local MiB = 1024 * 1024

local defaults = {
  bigfile_size = 2 * MiB,
  truncate_size = 20 * MiB,
  binary_sample_size = 8192,
  binary_control_ratio = 0.30,
  utf16_zero_ratio = 0.60,
  utf16_text_ratio = 0.60,
}

local group_name = "LocalBigFile"
local config = vim.deepcopy(defaults)

local function format_size(bytes)
  return ("%.1fMiB"):format(bytes / MiB)
end

local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO)
  end)
end

local function file_stat(path)
  local ok, stat = pcall(uv.fs_stat, path)
  if not ok then
    return nil
  end
  return stat
end

local function read_chunk(path, size)
  local fd, open_err = uv.fs_open(path, "r", 438)
  if not fd then
    return nil, open_err
  end

  local data, read_err = uv.fs_read(fd, size, 0)
  uv.fs_close(fd)

  return data or "", read_err
end

local function is_text_byte(byte)
  return byte == 9 or byte == 10 or byte == 12 or byte == 13 or byte == 27 or byte >= 32
end

local function likely_utf16(data)
  local pairs = math.floor(#data / 2)
  if pairs < 8 then
    return nil
  end

  local even_zero = 0
  local odd_zero = 0
  local even_text = 0
  local odd_text = 0

  for i = 1, pairs * 2, 2 do
    local odd = data:byte(i)
    local even = data:byte(i + 1)

    if odd == 0 then
      odd_zero = odd_zero + 1
    elseif is_text_byte(odd) then
      odd_text = odd_text + 1
    end

    if even == 0 then
      even_zero = even_zero + 1
    elseif is_text_byte(even) then
      even_text = even_text + 1
    end
  end

  if even_zero / pairs >= config.utf16_zero_ratio and odd_text / pairs >= config.utf16_text_ratio then
    return "utf-16le"
  end

  if odd_zero / pairs >= config.utf16_zero_ratio and even_text / pairs >= config.utf16_text_ratio then
    return "utf-16be"
  end

  return nil
end

local function inspect_sample(data)
  if not data or data == "" then
    return {
      binary = false,
      encoding = "utf-8",
    }
  end

  local first, second, third = data:byte(1, 3)
  if first == 0xEF and second == 0xBB and third == 0xBF then
    return {
      binary = false,
      encoding = "utf-8",
    }
  end

  if first == 0xFF and second == 0xFE then
    return {
      binary = false,
      encoding = "utf-16le",
    }
  end

  if first == 0xFE and second == 0xFF then
    return {
      binary = false,
      encoding = "utf-16be",
    }
  end

  local utf16 = likely_utf16(data)
  if utf16 then
    return {
      binary = false,
      encoding = utf16,
    }
  end

  local control = 0
  for i = 1, #data do
    local byte = data:byte(i)

    if byte == 0 then
      return {
        binary = true,
      }
    end

    if not is_text_byte(byte) then
      control = control + 1
    end
  end

  return {
    binary = control / #data > config.binary_control_ratio,
    encoding = "utf-8",
  }
end

local function current_buf_call(buf, fn)
  if vim.api.nvim_get_current_buf() == buf then
    fn()
    return
  end

  vim.api.nvim_buf_call(buf, fn)
end

local function detach_lsp(buf, client_id)
  if not vim.b[buf].bigfile then
    return
  end

  if client_id and vim.lsp.buf_detach_client then
    pcall(vim.lsp.buf_detach_client, buf, client_id)
  end

  if vim.lsp.get_clients and vim.lsp.buf_detach_client then
    for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
      pcall(vim.lsp.buf_detach_client, buf, client.id)
    end
  end
end

local function apply_bigfile_options(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.b[buf].bigfile = true

  current_buf_call(buf, function()
    vim.opt_local.swapfile = false
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.undolevels = -1
    vim.opt_local.undoreload = 0
    vim.opt_local.list = false
    vim.opt_local.spell = false
    vim.opt_local.syntax = "off"

    pcall(vim.cmd, "syntax clear")
    if vim.fn.exists ":NoMatchParen" == 2 then
      pcall(vim.cmd, "NoMatchParen")
    end
  end)

  if vim.treesitter and vim.treesitter.stop then
    pcall(vim.treesitter.stop, buf)
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.wo[win].wrap = false
      vim.wo[win].relativenumber = false
      vim.wo[win].cursorline = false
      vim.wo[win].cursorcolumn = false
      vim.wo[win].foldenable = false
    end
  end

  detach_lsp(buf)
end

local function run_bufreadpost(buf)
  vim.api.nvim_exec_autocmds("BufReadPost", {
    buffer = buf,
    modeline = false,
  })
end

local function remove_read_original_empty_line(buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count <= 1 then
    return
  end

  local last = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1]
  if last == "" then
    vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, {})
  end
end

local function read_default(buf, path)
  local ok, err = pcall(vim.cmd, "silent keepalt 0read ++edit " .. vim.fn.fnameescape(path))
  if not ok then
    notify(("Failed to read %s: %s"):format(path, err), vim.log.levels.ERROR)
    return false
  end

  remove_read_original_empty_line(buf)
  vim.bo[buf].modified = false
  return true
end

local function data_to_lines(data)
  if data == "" then
    return { "" }
  end

  local lines = vim.split(data, "\n", {
    plain = true,
  })

  if data:sub(-1) == "\n" then
    table.remove(lines)
  end

  for index, line in ipairs(lines) do
    if line:sub(-1) == "\r" then
      lines[index] = line:sub(1, -2)
    end
  end

  if #lines == 0 then
    return { "" }
  end

  return lines
end

local function trim_incomplete_utf8(data)
  local len = #data
  if len == 0 then
    return data
  end

  local start = len
  while start > math.max(1, len - 3) do
    local byte = data:byte(start)
    if byte < 0x80 or byte > 0xBF then
      break
    end
    start = start - 1
  end

  local first = data:byte(start)
  local expected
  if first >= 0xC2 and first <= 0xDF then
    expected = 2
  elseif first >= 0xE0 and first <= 0xEF then
    expected = 3
  elseif first >= 0xF0 and first <= 0xF4 then
    expected = 4
  end

  if expected and len - start + 1 < expected then
    return data:sub(1, start - 1)
  end

  return data
end

local function read_truncated(buf, path, size)
  local data, err = read_chunk(path, config.truncate_size)
  if not data then
    notify(("Failed to read %s: %s"):format(path, err), vim.log.levels.ERROR)
    return false
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, data_to_lines(trim_incomplete_utf8(data)))
  vim.bo[buf].modified = false
  vim.bo[buf].readonly = true
  vim.bo[buf].modifiable = false

  vim.b[buf].bigfile_truncated = true
  vim.b[buf].bigfile_original_size = size
  vim.b[buf].bigfile_loaded_size = math.min(size, config.truncate_size)

  notify(
    ("Opened first %s of %s (%s); buffer is read-only"):format(
      format_size(config.truncate_size),
      vim.fn.fnamemodify(path, ":t"),
      format_size(size)
    ),
    vim.log.levels.WARN
  )

  return true
end

local function close_blocked_buffer(buf)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.cmd, "silent! bdelete! " .. buf)
    end
  end)
end

local function block_file(buf, message)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false

  notify(message, vim.log.levels.WARN)
  close_blocked_buffer(buf)
end

local function block_binary(buf, path)
  vim.b[buf].binary_blocked = true
  block_file(buf, ("Refusing to open binary file: %s"):format(path))
end

local function block_unsupported_truncation(buf, path, encoding, size)
  vim.b[buf].bigfile_blocked = true
  block_file(
    buf,
    ("Refusing to open %s file above %s without full read: %s (%s)"):format(
      encoding,
      format_size(config.truncate_size),
      path,
      format_size(size)
    )
  )
end

local function read_regular_file(args)
  local buf = args.buf
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    path = args.file or args.match
  end

  local stat = file_stat(path)
  if not stat or stat.type ~= "file" then
    if read_default(buf, path) then
      run_bufreadpost(buf)
    end
    return
  end

  local sample_size = math.min(stat.size, config.binary_sample_size)
  local sample, sample_err = read_chunk(path, sample_size)
  if not sample then
    notify(("Failed to inspect %s: %s"):format(path, sample_err), vim.log.levels.ERROR)
    close_blocked_buffer(buf)
    return
  end

  local inspection = inspect_sample(sample)
  if inspection.binary then
    block_binary(buf, path)
    return
  end

  local is_bigfile = stat.size >= config.bigfile_size
  local should_truncate = stat.size >= config.truncate_size

  if should_truncate and inspection.encoding ~= "utf-8" then
    block_unsupported_truncation(buf, path, inspection.encoding or "non-utf-8", stat.size)
    return
  end

  if is_bigfile then
    apply_bigfile_options(buf)
    vim.b[buf].bigfile_size = stat.size
    vim.b[buf].bigfile_encoding = inspection.encoding
  end

  local ok
  if should_truncate then
    ok = read_truncated(buf, path, stat.size)
  else
    ok = read_default(buf, path)
  end

  if not ok then
    close_blocked_buffer(buf)
    return
  end

  if is_bigfile then
    apply_bigfile_options(buf)
    notify(
      ("Big file mode enabled for %s (%s)"):format(vim.fn.fnamemodify(path, ":t"), format_size(stat.size)),
      vim.log.levels.INFO
    )
  end

  run_bufreadpost(buf)
end

local function protect_truncated_write(args)
  if not vim.b[args.buf].bigfile_truncated then
    return
  end

  error "Refusing to write a truncated bigfile buffer"
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  local group = vim.api.nvim_create_augroup(group_name, {
    clear = true,
  })

  -- BufReadPre cannot abort Neovim's default read path reliably. Use a thin
  -- BufReadCmd dispatcher so binary and truncated buffers are never fully read.
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "*",
    callback = read_regular_file,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      if vim.b[args.buf].bigfile then
        apply_bigfile_options(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      if vim.b[args.buf].bigfile then
        vim.schedule(function()
          detach_lsp(args.buf, args.data and args.data.client_id)
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(args)
      if vim.b[args.buf].bigfile then
        apply_bigfile_options(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    callback = protect_truncated_write,
  })
end

return M
