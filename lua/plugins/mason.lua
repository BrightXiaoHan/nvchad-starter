local opts = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",

    -- python stuff
    "pyright",
    "black",
    "isort",
    "autoflake",

    -- dap
    "debugpy",
  },
}

local plugin = {
  "williamboman/mason.nvim",
  opts = opts,
  cond = function()
    return not vim.g.vscode
  end,
}

return plugin
