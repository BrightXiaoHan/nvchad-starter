local M = {}

local uv = vim.uv or vim.loop

local root_markers = {
  ".git",
  "Makefile",
  "package.json",
  "pyproject.toml",
  "Cargo.toml",
  "go.mod",
}

local ignore_globs = {
  "!.git",
  "!.venv",
  "!__pycache__",
  "!node_modules",
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function root_dir()
  return vim.fs.root(0, root_markers) or uv.cwd()
end

local function rg_args(...)
  local args = { "rg", "--hidden" }
  for _, glob in ipairs(ignore_globs) do
    args[#args + 1] = "-g"
    args[#args + 1] = glob
  end

  for _, arg in ipairs { ... } do
    args[#args + 1] = arg
  end

  return args
end

local function run(args, cwd, on_done)
  vim.system(args, {
    cwd = cwd,
    text = true,
  }, function(result)
    vim.schedule(function()
      on_done(result)
    end)
  end)
end

local function split_lines(text)
  if not text or text == "" then
    return {}
  end

  return vim.split(vim.trim(text), "\n", {
    plain = true,
  })
end

local function open_file(path)
  if not path or path == "" then
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function fallback_files(root)
  local files = vim.fn.globpath(root, "**/*", false, true)
  local result = {}

  for _, file in ipairs(files) do
    if vim.fn.isdirectory(file) == 0 then
      result[#result + 1] = file
    end
  end

  table.sort(result)
  return result
end

function M.find_files()
  local root = root_dir()

  local function select_file(files)
    if #files == 0 then
      notify("No files found", vim.log.levels.WARN)
      return
    end

    vim.ui.select(files, {
      prompt = "Find file",
      format_item = function(item)
        return vim.fn.fnamemodify(item, ":.")
      end,
    }, open_file)
  end

  if vim.fn.executable "rg" == 0 then
    select_file(fallback_files(root))
    return
  end

  run(rg_args "--files", root, function(result)
    if result.code ~= 0 and result.stdout == "" then
      notify(result.stderr ~= "" and result.stderr or "rg --files failed", vim.log.levels.ERROR)
      return
    end

    local files = {}
    for _, file in ipairs(split_lines(result.stdout)) do
      files[#files + 1] = vim.fs.joinpath(root, file)
    end
    select_file(files)
  end)
end

local function set_quickfix(title, items)
  vim.fn.setqflist({}, " ", {
    title = title,
    items = items,
  })

  if #items == 0 then
    notify("No matches", vim.log.levels.WARN)
    return
  end

  vim.cmd.copen()
  vim.cmd.cc(1)
end

function M.live_grep()
  if vim.fn.executable "rg" == 0 then
    notify("rg is not installed", vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = "Live grep: ",
  }, function(query)
    if not query or query == "" then
      return
    end

    local root = root_dir()
    local args = rg_args("--vimgrep", "--smart-case", query)

    run(args, root, function(result)
      if result.code > 1 then
        notify(result.stderr ~= "" and result.stderr or "rg failed", vim.log.levels.ERROR)
        return
      end

      local items = {}
      for _, line in ipairs(split_lines(result.stdout)) do
        local file, lnum, col, text = line:match "^(.-):(%d+):(%d+):(.*)$"
        if file then
          items[#items + 1] = {
            filename = vim.fs.joinpath(root, file),
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = text,
          }
        end
      end

      set_quickfix("Live grep: " .. query, items)
    end)
  end)
end

function M.current_buffer_find()
  local bufnr = vim.api.nvim_get_current_buf()

  vim.ui.input({
    prompt = "Find in buffer: ",
  }, function(query)
    if not query or query == "" then
      return
    end

    local items = {}
    for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
      local start = 1
      while true do
        local from = line:lower():find(query:lower(), start, true)
        if not from then
          break
        end

        items[#items + 1] = {
          bufnr = bufnr,
          lnum = lnum,
          col = from,
          text = line,
        }
        start = from + 1
      end
    end

    set_quickfix("Buffer find: " .. query, items)
  end)
end

function M.oldfiles()
  local files = {}
  local seen = {}

  for _, file in ipairs(vim.v.oldfiles or {}) do
    if not seen[file] and vim.fn.filereadable(file) == 1 then
      seen[file] = true
      files[#files + 1] = file
    end
  end

  if #files == 0 then
    notify("No recent files", vim.log.levels.WARN)
    return
  end

  vim.ui.select(files, {
    prompt = "Recent files",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":~:.")
    end,
  }, open_file)
end

function M.setup()
  if vim.g.vscode then
    return
  end

  vim.api.nvim_create_user_command("LocalFindFiles", M.find_files, {})
  vim.api.nvim_create_user_command("LocalLiveGrep", M.live_grep, {})
  vim.api.nvim_create_user_command("LocalBufferFind", M.current_buffer_find, {})
  vim.api.nvim_create_user_command("LocalOldfiles", M.oldfiles, {})

  vim.keymap.set("n", "<C-p>", M.find_files, {
    desc = "Find file",
  })
  vim.keymap.set("n", "<C-f>", M.live_grep, {
    desc = "Fuzzy find",
  })
  vim.keymap.set("n", "<leader>f", M.current_buffer_find, {
    desc = "Find",
  })
end

return M
