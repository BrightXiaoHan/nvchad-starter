local function config()
  require("nvchad.configs.lspconfig").defaults()
  local on_attach = require("nvchad.configs.lspconfig").on_attach
  local capabilities = require("nvchad.configs.lspconfig").capabilities

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
    vim.keymap.set("n", "<leader>li", "<cmd>PyRemoveUnusedImports<cr>", {
      desc = "Remove unused imports",
    })
    vim.keymap.set("n", "<leader>ll", "<cmd>LspRestart<cr>", {
      desc = "Restart LSP",
    })
  end,
}

return plugin
