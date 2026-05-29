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
  local function pack_stats()
    local ok, packs = pcall(vim.pack.get)
    if not ok then
      return "  Loaded plugins with vim.pack"
    end

    local loaded = 0
    for _, pack in ipairs(packs) do
      if pack.active then
        loaded = loaded + 1
      end
    end

    return "  Loaded " .. loaded .. "/" .. #packs .. " plugins with vim.pack"
  end

  M.nvdash = {
    load_on_startup = true,
    buttons = function()
      return {
        { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
        { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
        { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
        { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
        { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
        { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
        {
          txt = pack_stats,
          hl = "NvDashFooter",
          no_gap = true,
          content = "fit",
        },
        { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
      }
    end,
  }
end

return M
