-- if win32, use pwsh
-- otherwise, use fish
if vim.fn.has "win32" == 1 then
  SHELL = "pwsh"
else
  SHELL = "fish"
end

local opts = {
  shell = SHELL,
}
local plugin = { "akinsho/toggleterm.nvim", config = true, lazy = false, opts = opts }

return plugin
