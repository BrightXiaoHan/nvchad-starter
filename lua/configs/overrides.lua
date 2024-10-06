local M = {}

M.treesitter = {
  ensure_installed = {
    "lua",
    "c",
    "cpp",
    "fish",
    "python",
    "bash",
    "markdown",
    "cmake",
    "dockerfile",
    "yaml",
  },
  indent = {
    enable = true,
    disable = {},
  },
}

M.mason = {
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
    "debugpy"
  },
}

local function nvimtree_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)
  local open_preview = require("cmd").nvim_tree_open_preview
  local tsz = require("cmd").nvim_tree_tsz
  local trz = require("cmd").nvim_tree_trz

  vim.keymap.set("n", "l", open_preview, opts "Open: Preview")
  vim.keymap.set("n", "v", api.node.open.vertical, opts "Open: Vertical Split")
  vim.keymap.set("n", "h", api.node.open.horizontal, opts "Open: Horizontal Split")
  if vim.env.SSH_TTY then
    vim.keymap.set("n", "t", tsz, opts "Open: tsz")
    vim.keymap.set("n", "s", trz, opts "Open: trz")
  end
end

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
    ignore = false,
  },
  update_focused_file = {
    enable = false,
  },

  filters = { custom = { "^.git$", "^__pycache__", "^.venv" } },

  on_attach = nvimtree_attach,

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

M.cmp = {
  mapping = {
    ["<Up>"] = require("cmp").mapping.select_prev_item(),
    ["<Down>"] = require("cmp").mapping.select_next_item(),
    ["<C-e>"] = require("cmp").mapping.close(),
    ["<Tab>"] = require("cmp").config.disable,
  },
  sources = {
    { name = "path" },
    { name = "nvim_lsp", max_item_count = 3 },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "treesitter" },
  },
  -- disable auto-complete
  -- completion = {
  -- 	autocomplete = false,
  -- },
}

-- if win32 then use powershell else fish
if vim.fn.has "win32" == 1 then
  SHELL = "pwsh.exe"
else
  SHELL = "fish"
end

M.nvterm = {
  terminals = {
    shell = SHELL,
    type_opts = {
      horizontal = { location = "rightbelow", split_ratio = 0.5, size = 50 },
    },
  },
}

return M
