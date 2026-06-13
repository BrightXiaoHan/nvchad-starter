local function config()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local servers = { "clangd", "pyright", "lua_ls", "bashls" }

  local server_configs = {
    pyright = {
      -- disable diagnostics
      settings = {
        python = {
          analysis = {
            diagnosticMode = "off",
            typeCheckingMode = "off",
          },
        },
      },
    },
    lua_ls = {
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
    },
  }

  for _, lsp in ipairs(servers) do
    local server_config = vim.tbl_deep_extend("force", {
      capabilities = capabilities,
    }, server_configs[lsp] or {})

    vim.lsp.config(lsp, server_config)
  end

  vim.lsp.enable(servers)
end

local plugin = {
  "neovim/nvim-lspconfig",
  config = config,
  init = function()
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
