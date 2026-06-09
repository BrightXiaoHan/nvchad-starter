local M = {}

local disabled_builtin_plugins = {
  "2html_plugin",
  "tohtml",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "matchit",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
  "tutor",
  "rplugin",
  "syntax",
  "synmenu",
  "optwin",
  "compiler",
  "bugreport",
  "ftplugin",
}

local branch_by_name = {
  ["base46"] = "v3.0",
  ["cmp-buffer"] = "main",
  ["cmp-nvim-lsp"] = "main",
  ["cmp-nvim-lua"] = "main",
  ["cmp-path"] = "main",
  ["conform.nvim"] = "master",
  ["diffview.nvim"] = "main",
  ["flatten.nvim"] = "main",
  ["fzf-lua"] = "main",
  ["gitsigns.nvim"] = "main",
  ["neogit"] = "master",
  ["nvim-cmp"] = "main",
  ["nvim-lspconfig"] = "master",
  ["nvim-tree.lua"] = "master",
  ["nvim-web-devicons"] = "master",
  ["plenary.nvim"] = "master",
  ["telescope.nvim"] = "master",
  ["ui"] = "v3.0",
  ["volt"] = "main",
  ["which-key.nvim"] = "main",
}

local main_by_name = {
  ["nvim-cmp"] = "cmp",
  ["nvim-tree.lua"] = "nvim-tree",
}

local pending_builds = {}
local pack_setup_done = false

local function disable_builtin_plugins()
  for _, plugin in ipairs(disabled_builtin_plugins) do
    vim.g["loaded_" .. plugin] = 1
  end
end

local function is_list(value)
  return type(value) == "table" and vim.islist(value)
end

local function is_plugin_spec(spec)
  return type(spec) == "string"
    or type(spec) == "table" and (type(spec[1]) == "string" or spec.src ~= nil or spec.dir ~= nil)
end

local function flatten_specs(specs, result)
  result = result or {}

  if not specs then
    return result
  end

  for _, spec in ipairs(specs) do
    if is_plugin_spec(spec) then
      result[#result + 1] = spec
    elseif is_list(spec) then
      flatten_specs(spec, result)
    end
  end

  return result
end

local function github_source(source)
  if source:match "^%a[%w+.-]*://" or source:match "^git@" or source:match "^/" or source:match "^%.%.?/" then
    return source
  end

  return "https://github.com/" .. source
end

local function name_from_source(source)
  return (source:gsub("%.git$", ""):match "[^/]+$") or source
end

local function normalize_spec(spec)
  if type(spec) == "string" then
    spec = { spec }
  else
    spec = vim.deepcopy(spec)
  end

  local source = spec.src or not spec.dir and spec[1] or nil
  local name = spec.name or source and name_from_source(source) or spec[1] or spec.dir and name_from_source(spec.dir)
  spec.name = name
  spec.src = source and github_source(source) or nil

  return spec
end

local function spec_enabled(spec)
  if type(spec.cond) == "function" then
    return spec.cond() ~= false
  end

  return spec.cond ~= false
end

local function collect_specs(specs)
  local runtime_specs = {}
  local pack_specs_by_name = {}
  local pack_names = {}

  local function add_pack_spec(spec)
    if not spec.src or pack_specs_by_name[spec.name] then
      return
    end

    local pack_spec = {
      src = spec.src,
      name = spec.name,
      version = spec.version or branch_by_name[spec.name],
    }

    pack_specs_by_name[spec.name] = pack_spec
    pack_names[#pack_names + 1] = spec.name
  end

  local function add_dependencies(spec)
    for _, dep in ipairs(flatten_specs(spec.dependencies)) do
      dep = normalize_spec(dep)
      if spec_enabled(dep) then
        add_dependencies(dep)
        add_pack_spec(dep)
      end
    end
  end

  for _, spec in ipairs(flatten_specs(specs)) do
    spec = normalize_spec(spec)

    if spec_enabled(spec) then
      add_dependencies(spec)
      add_pack_spec(spec)
      runtime_specs[#runtime_specs + 1] = spec
    end
  end

  local pack_specs = {}
  for _, name in ipairs(pack_names) do
    pack_specs[#pack_specs + 1] = pack_specs_by_name[name]
  end

  return runtime_specs, pack_specs
end

local function source_runtime_files(path, subdir)
  local patterns = {
    subdir .. "/**/*.vim",
    subdir .. "/**/*.lua",
  }

  for _, pattern in ipairs(patterns) do
    for _, file in ipairs(vim.fn.glob(vim.fs.joinpath(path, pattern), false, true)) do
      vim.cmd.source { file, magic = { file = false } }
    end
  end
end

local function load_local_plugin(spec)
  if not spec.dir or vim.fn.isdirectory(spec.dir) == 0 then
    return
  end

  vim.opt.rtp:prepend(spec.dir)
  source_runtime_files(spec.dir, "plugin")
  source_runtime_files(spec.dir, "ftdetect")
end

local function infer_main(spec)
  if spec.main then
    return spec.main
  end

  local name = spec.name
  return main_by_name[name] or name:gsub("%.nvim$", ""):gsub("%.lua$", "")
end

local function resolve_opts(spec)
  if type(spec.opts) == "function" then
    return spec.opts(spec)
  end

  return spec.opts
end

local function run_config(spec)
  if spec.config == false then
    return
  end

  local opts = resolve_opts(spec)

  if type(spec.config) == "function" then
    spec.config(spec, opts)
    return
  end

  if spec.config == true or opts ~= nil then
    require(infer_main(spec)).setup(opts or {})
  end
end

local function run_build(build, path)
  if type(build) == "function" then
    build(path)
  elseif type(build) == "string" then
    vim.cmd(build:gsub("^:", ""))
  elseif type(build) == "table" then
    vim.system(build, { cwd = path }):wait()
  end
end

local function run_pack_build(name, path, build)
  pcall(vim.cmd.packadd, { name, magic = { file = false } })
  run_build(build, path)
end

local function setup_build_hooks(runtime_specs)
  local build_by_plugin = {}

  for _, spec in ipairs(runtime_specs) do
    if spec.build and spec.name then
      build_by_plugin[spec.name] = spec.build
    end
  end

  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("PackBuildHooks", { clear = true }),
    callback = function(ev)
      if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
        return
      end

      local build = build_by_plugin[ev.data.spec.name]
      if not build then
        return
      end

      local name = ev.data.spec.name
      if not pack_setup_done then
        pending_builds[#pending_builds + 1] = {
          name = name,
          path = ev.data.path,
          build = build,
        }
        return
      end

      run_pack_build(name, ev.data.path, build)
    end,
  })
end

local function run_pending_builds()
  pack_setup_done = true

  for _, item in ipairs(pending_builds) do
    run_pack_build(item.name, item.path, item.build)
  end

  pending_builds = {}
end

function M.setup(specs)
  if not vim.pack then
    error "This config requires Neovim 0.12 or newer for vim.pack"
  end

  disable_builtin_plugins()

  local runtime_specs, pack_specs = collect_specs(specs)

  for _, spec in ipairs(runtime_specs) do
    if type(spec.init) == "function" then
      spec.init(spec)
    end
  end

  setup_build_hooks(runtime_specs)

  vim.pack.add(pack_specs, { confirm = false, load = true })
  run_pending_builds()

  for _, spec in ipairs(runtime_specs) do
    load_local_plugin(spec)
  end

  for _, spec in ipairs(runtime_specs) do
    run_config(spec)
  end
end

return M
