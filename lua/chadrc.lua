---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "vscode_dark",
  theme_toggle = { "blossom_light", "vscode_dark" },

  hl_override = {
    Comment = {
      italic = true,
    },
  },
  hl_add = {
    NvimTreeOpenedFolderName = { fg = "green", bold = true },
  },

  nvdash = {
    load_on_startup = true,
  },
}

return M
