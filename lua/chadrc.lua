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

  nvdash = {
    load_on_startup = true,
  },
}

return M
