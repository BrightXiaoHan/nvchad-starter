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
  vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", {
    desc = "Explorer",
  })

end

-- git support in nvimtree
local opts = {
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

local plugin = {
  "nvim-tree/nvim-tree.lua",
  opts = opts,
}

return plugin
