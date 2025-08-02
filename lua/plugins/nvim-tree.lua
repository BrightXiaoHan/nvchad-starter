local function nvim_tree_open_preview()
  local api = require "nvim-tree.api"
  -- if current node is a folder, open it
  local node = api.tree.get_node_under_cursor()
  -- nil check
  if not node then
    return
  end

  if node.type == "directory" then
    api.node.open.preview()
    return
  end

  -- if current node is a file, open preview it and switch to the window
  api.node.open.preview()
  vim.cmd "wincmd l"
end

local function nvimtree_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)
  local open_preview = nvim_tree_open_preview

  vim.keymap.set("n", "l", open_preview, opts "Open: Preview")
  vim.keymap.set("n", "v", api.node.open.vertical, opts "Open: Vertical Split")
  vim.keymap.set("n", "h", api.node.open.horizontal, opts "Open: Horizontal Split")
end

-- git support in nvimtree
local opts = {
  git = {
    enable = true,
    ignore = false,
  },

  filters = { dotfiles = false, custom = { "^.git$", "^__pycache__", "^.venv" } },

  on_attach = nvimtree_attach,

  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = false,
    update_root = false,
  },
  view = {
    width = 30,
    preserve_window_proportions = true,
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,

    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = { unmerged = "" },
      },
      show = {
        git = true,
      },
    },
  },
}

local plugin = {
  "nvim-tree/nvim-tree.lua",
  opts = opts,
  init = function()
    -- nvim-tree
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", {
      desc = "Explorer",
    })
  end,
  cond = function()
    return not vim.g.vscode
  end,
  lazy = false,
}

return plugin
