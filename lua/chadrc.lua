---@type ChadrcConfig
local M = {}

M.ui = {
  hl_override = {
    Comment = {
      italic = true,
    },
  },
  hl_add = {
    NvimTreeOpenedFolderName = { fg = "green", bold = true },
  },
}

if vim.g.vscode then
  M.nvdash = {
    enabled = false,
  }
  M.ui.tabufline = {
    enabled = false,
  }
else
  M.nvdash = {
    load_on_startup = true,
  }
end

return M
