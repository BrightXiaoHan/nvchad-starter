local on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>ra", require "nvchad.lsp.renamer", opts "NvRenamer")
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

local defaults = function()
  dofile(vim.g.base46_cache .. "lsp")
  require("nvchad.lsp").diagnostic_config()

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(_, args.buf)
    end,
  })

  local lua_lsp_settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  }

  -- Support 0.10 temporarily

  if vim.lsp.config then
    vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
    vim.lsp.config("lua_ls", { settings = lua_lsp_settings })
    vim.lsp.enable "lua_ls"
  else
    require("lspconfig").lua_ls.setup {
      capabilities = M.capabilities,
      on_init = M.on_init,
      settings = lua_lsp_settings,
    }
  end
end

local function config()
  defaults()

  local lspconfig = require "lspconfig"

  -- if you just want default config for the servers then put them in a table
  local servers = { "clangd", "pyright", "lua_ls", "bashls" }

  for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
      on_attach = on_attach,
      capabilities = capabilities,
    }
  end

  --
  lspconfig.pyright.setup {
    -- disable diagnostics
    settings = {
      python = {
        analysis = {
          diagnosticMode = "off",
          typeCheckingMode = "off",
        },
      },
    },
  }

  lspconfig.lua_ls.setup {
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using
          -- (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT",
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = {
            "vim",
            "require",
          },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
  }
end

local plugin = {
  "neovim/nvim-lspconfig",
  config = config,
  init = function()
    vim.keymap.set("n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", {
      desc = "Rename",
    })
    vim.keymap.set("n", "<leader>ld", "<cmd>lua vim.diagnostic.open_float(0, {scope='line'})<CR>", {
      desc = "Line diagnostics",
    })
    vim.keymap.set("n", "<leader>lp", "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>", {
      desc = "Previous diagnostic",
    })
    vim.keymap.set("n", "<leader>ln", "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>", {
      desc = "Next diagnostic",
    })
    vim.keymap.set("n", "<C-LeftMouse>", "<cmd>lua vim.lsp.buf.definition()<cr>", {
      desc = "Go to definition",
    })
    vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", {
      desc = "Go to definition",
    })
    vim.keymap.set("n", "<C-RightMouse>", "<cmd>lua vim.lsp.buf.references()<cr>", {
      desc = "Go to references",
    })
    vim.keymap.set("n", "<leader>ll", "<cmd>LspRestart<cr>", {
      desc = "Restart LSP",
    })
  end,
}

return plugin
