local M = {}

local server_names = { "clangd", "pyright", "lua_ls", "bashls" }

local function clangd_switch_source_header(bufnr, client)
  local method = "textDocument/switchSourceHeader"
  if not client or not client:supports_method(method) then
    vim.notify("clangd switch source/header is not available", vim.log.levels.WARN)
    return
  end

  local params = vim.lsp.util.make_text_document_params(bufnr)
  client:request(method, params, function(err, result)
    if err then
      vim.notify(tostring(err), vim.log.levels.ERROR)
      return
    end

    if not result then
      vim.notify("Corresponding source/header file cannot be determined", vim.log.levels.WARN)
      return
    end

    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end

local function clangd_symbol_info(bufnr, client)
  local method = "textDocument/symbolInfo"
  if not client or not client:supports_method(method) then
    vim.notify("clangd symbol info is not available", vim.log.levels.WARN)
    return
  end

  local win = vim.api.nvim_get_current_win()
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  client:request(method, params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      return
    end

    local name = "name: " .. (result[1].name or "")
    local container = "container: " .. (result[1].containerName or "")
    vim.lsp.util.open_floating_preview({ name, container }, "", {
      focus = false,
      focusable = false,
      height = 2,
      title = "Symbol Info",
      width = math.max(#name, #container),
    })
  end, bufnr)
end

local function pyright_set_python_path(command)
  local python_path = command.args
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = "pyright",
  }

  for _, client in ipairs(clients) do
    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
      python = {
        pythonPath = python_path,
      },
    })

    client:notify("workspace/didChangeConfiguration", {
      settings = nil,
    })
  end
end

local function pyright_organize_imports(bufnr, client)
  client:request("workspace/executeCommand", {
    command = "pyright.organizeimports",
    arguments = { vim.uri_from_bufnr(bufnr) },
  }, nil, bufnr)
end

local function server_configs()
  return {
    clangd = {
      cmd = { "clangd" },
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
      root_markers = {
        ".clangd",
        ".clang-tidy",
        ".clang-format",
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac",
        ".git",
      },
      capabilities = {
        offsetEncoding = { "utf-8", "utf-16" },
        textDocument = {
          completion = {
            editsNearCursor = true,
          },
        },
      },
      on_init = function(client, init_result)
        if init_result and init_result.offsetEncoding then
          client.offset_encoding = init_result.offsetEncoding
        end
      end,
      on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
          clangd_switch_source_header(bufnr, client)
        end, { desc = "Switch between source/header" })

        vim.api.nvim_buf_create_user_command(bufnr, "LspClangdShowSymbolInfo", function()
          clangd_symbol_info(bufnr, client)
        end, { desc = "Show clangd symbol info" })
      end,
    },

    pyright = {
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_markers = {
        "pyrightconfig.json",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
      },
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "off",
            typeCheckingMode = "off",
            useLibraryCodeForTypes = true,
          },
        },
      },
      on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightOrganizeImports", function()
          pyright_organize_imports(bufnr, client)
        end, { desc = "Organize imports with pyright" })

        vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightSetPythonPath", pyright_set_python_path, {
          complete = "file",
          desc = "Set pyright python path",
          nargs = 1,
        })
      end,
    },

    lua_ls = {
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = {
        ".emmyrc.json",
        ".luarc.json",
        ".luarc.jsonc",
        ".luacheckrc",
        ".stylua.toml",
        "stylua.toml",
        "selene.toml",
        "selene.yml",
        ".git",
      },
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            globals = { "vim", "require" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
          },
          telemetry = {
            enable = false,
          },
        },
      },
    },

    bashls = {
      cmd = { "bash-language-server", "start" },
      filetypes = { "bash", "sh" },
      root_markers = { ".git" },
      settings = {
        bashIde = {
          globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
        },
      },
    },
  }
end

local function with_capabilities(config, capabilities)
  local merged = vim.deepcopy(config)
  merged.capabilities = vim.tbl_deep_extend("force", vim.deepcopy(capabilities), merged.capabilities or {})
  return merged
end

local function setup_servers()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local configs = server_configs()

  for _, name in ipairs(server_names) do
    vim.lsp.config(name, with_capabilities(configs[name], capabilities))
  end

  vim.lsp.enable(server_names)
end

local function setup_completion()
  vim.opt.completeopt:append { "menuone", "noselect", "popup" }

  vim.keymap.set("i", "<C-Space>", function()
    vim.lsp.completion.get()
  end, {
    desc = "Trigger LSP completion",
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LocalLspCompletion", { clear = true }),
    callback = function(args)
      if vim.g.vscode then
        return
      end

      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method "textDocument/completion" then
        vim.lsp.completion.enable(true, client.id, args.buf, {
          autotrigger = true,
        })
      end
    end,
  })
end

local function setup_keymaps()
  vim.keymap.set("n", "<leader>lr", function()
    vim.lsp.buf.rename()
  end, {
    desc = "Rename",
  })

  vim.keymap.set("n", "<leader>ld", function()
    vim.diagnostic.open_float(0, { scope = "line" })
  end, {
    desc = "Line diagnostics",
  })

  vim.keymap.set("n", "<leader>lp", function()
    vim.diagnostic.jump { count = -1, float = true }
  end, {
    desc = "Previous diagnostic",
  })

  vim.keymap.set("n", "<leader>ln", function()
    vim.diagnostic.jump { count = 1, float = true }
  end, {
    desc = "Next diagnostic",
  })

  vim.keymap.set("n", "<C-LeftMouse>", function()
    vim.lsp.buf.definition()
  end, {
    desc = "Go to definition",
  })

  vim.keymap.set("n", "gd", function()
    vim.lsp.buf.definition()
  end, {
    desc = "Go to definition",
  })

  vim.keymap.set("n", "<C-RightMouse>", function()
    vim.lsp.buf.references()
  end, {
    desc = "Go to references",
  })

  vim.keymap.set("n", "<leader>ll", "<cmd>LspRestart<cr>", {
    desc = "Restart LSP",
  })
end

function M.setup()
  setup_completion()
  setup_keymaps()
  setup_servers()
end

return M
