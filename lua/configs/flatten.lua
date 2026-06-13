local M = {}

local uv = vim.uv or vim.loop
local blocks = {}
local group = vim.api.nvim_create_augroup("LocalFlatten", { clear = false })

local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.WARN, { title = "local flatten" })
  end)
end

local function is_absolute(path)
  if path:match "^%a[%w+.-]*://" then
    return true
  end

  if vim.fn.has "win32" == 1 then
    return path:match "^%a:[/\\]" ~= nil or path:match "^[/\\][/\\]" ~= nil
  end

  return path:sub(1, 1) == "/"
end

local function resolve_path(cwd, path)
  if is_absolute(path) then
    return vim.fs.normalize(path)
  end

  return vim.fs.normalize(vim.fs.joinpath(cwd, path))
end

local function basename(path)
  return path:gsub("\\", "/"):match "([^/]+)$" or path
end

local function should_block_path(path)
  local name = basename(path)
  if name == "COMMIT_EDITMSG" or name == "MERGE_MSG" or name == "TAG_EDITMSG" or name == "git-rebase-todo" then
    return true
  end

  local normalized = path:gsub("\\", "/")
  return normalized:match "/%.git/rebase%-merge/" ~= nil or normalized:match "/%.git/rebase%-apply/" ~= nil
end

local function parse_post_commands(argv)
  local commands = {}
  local next_is_command = false

  for _, arg in ipairs(argv) do
    if next_is_command then
      commands[#commands + 1] = arg
      next_is_command = false
    elseif arg == "-c" then
      next_is_command = true
    elseif arg:sub(1, 1) == "+" and #arg > 1 then
      commands[#commands + 1] = arg:sub(2)
    end
  end

  return commands
end

local function ensure_server()
  if vim.v.servername and vim.v.servername ~= "" then
    return vim.v.servername
  end

  local ok, server = pcall(vim.fn.serverstart)
  if ok then
    return server
  end
end

local function connect(pipe)
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", pipe, { rpc = true })
  if ok and type(chan) == "number" then
    return chan
  end
end

local function execute_commands(commands)
  for _, command in ipairs(commands or {}) do
    local ok, err = pcall(vim.cmd, command)
    if not ok then
      notify(("Failed to run forwarded command '%s': %s"):format(command, err), vim.log.levels.ERROR)
    end
  end
end

local function open_files(files)
  local first_buf

  for index, file in ipairs(files) do
    if index == 1 then
      vim.cmd("tabedit " .. vim.fn.fnameescape(file))
      first_buf = vim.api.nvim_get_current_buf()
    else
      local bufnr = vim.fn.bufadd(file)
      vim.bo[bufnr].buflisted = true
    end
  end

  return first_buf
end

local function release_guest(pipe, token)
  local chan = connect(pipe)
  if not chan then
    notify(("Failed to connect to waiting nvim guest: %s"):format(pipe))
    return
  end

  pcall(vim.fn.rpcnotify, chan, "nvim_exec_lua", "require('configs.flatten')._release_block(...)", { token })
  pcall(vim.fn.chanclose, chan)
end

function M._release_block(token)
  blocks[token] = false
end

function M._host_open(payload)
  payload = payload or {}

  local files = {}
  for _, file in ipairs(payload.files or {}) do
    if file ~= "" and file ~= "-" then
      files[#files + 1] = resolve_path(payload.guest_cwd or vim.fn.getcwd(-1, -1), file)
    end
  end

  local block = payload.force_block == true
  for _, file in ipairs(files) do
    block = block or should_block_path(file)
  end

  local bufnr
  if #files > 0 then
    local ok, result = pcall(open_files, files)
    if not ok then
      notify(("Failed to open forwarded file: %s"):format(result), vim.log.levels.ERROR)
      return false
    end
    bufnr = result
  end

  execute_commands(payload.post_commands)

  if block and bufnr and payload.response_pipe and payload.token then
    vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete", "BufWipeout" }, {
      group = group,
      buffer = bufnr,
      once = true,
      callback = function()
        release_guest(payload.response_pipe, payload.token)
      end,
    })
  end

  return block and bufnr ~= nil
end

local function wait_for_block(token, host_chan)
  local ok = vim.wait(0x7fffffff, function()
    if blocks[token] == false then
      return true
    end

    local chan_ok, info = pcall(vim.api.nvim_get_chan_info, host_chan)
    return not chan_ok or vim.tbl_isempty(info)
  end, 200, false)

  if not ok then
    notify "Interrupted while waiting for forwarded editor session"
  end
end

local function quit_guest()
  vim.cmd "silent! qall!"
end

local function forward_to_host(host_chan)
  local files = vim.fn.argv()
  local token = ("%s:%s"):format(vim.fn.getpid(), uv.hrtime())

  blocks[token] = true

  local payload = {
    files = files,
    guest_cwd = vim.fn.getcwd(-1, -1),
    response_pipe = ensure_server(),
    token = token,
    force_block = vim.g.flatten_wait ~= nil,
    post_commands = parse_post_commands(vim.v.argv),
  }

  local ok, should_block = pcall(
    vim.fn.rpcrequest,
    host_chan,
    "nvim_exec_lua",
    "return require('configs.flatten')._host_open(...)",
    { payload }
  )

  if not ok then
    blocks[token] = nil
    notify(("Failed to forward nested nvim session: %s"):format(should_block), vim.log.levels.ERROR)
    return false
  end

  if should_block then
    wait_for_block(token, host_chan)
  end

  blocks[token] = nil
  quit_guest()
  return true
end

function M.setup()
  if vim.env.NVIM == nil or vim.env.NVIM == "" then
    return
  end

  local host_chan = connect(vim.env.NVIM)
  if not host_chan then
    notify(("Failed to connect to outer nvim instance: %s"):format(vim.env.NVIM))
    return
  end

  forward_to_host(host_chan)
end

return M
