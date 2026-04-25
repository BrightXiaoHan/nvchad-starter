local function has_codeium_auth()
  local config_file = vim.fn.expand("~/.codeium/config.json")
  if vim.fn.filereadable(config_file) == 0 then
    return false
  end
  local content = table.concat(vim.fn.readfile(config_file), "\n")
  local ok, config = pcall(vim.json.decode, content)
  return ok and config and config.apiKey ~= nil
end

local plugin = {
  "Exafunction/windsurf.vim",
  cond = function()
    return not vim.g.vscode
  end,
  event = "BufReadPost",
  init = function()
    if not has_codeium_auth() then
      vim.g.codeium_enabled = 0
    end
  end,
  config = function()
    -- Change '<C-g>' here to any keycode you like.
    vim.keymap.set("i", "<Tab>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true, silent = true })
  end,
}

return plugin
