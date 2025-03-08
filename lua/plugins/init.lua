local function load_plugins()
  -- Use vim.fn.glob to get all .lua files in the folder
  local all_config = {}

  local plugin_dir = vim.fn.stdpath "config" .. "/lua/plugins"

  local files = vim.fn.readdir(plugin_dir)

  for _, file in ipairs(files) do
    if file:match "%.lua$" and file ~= "init.lua" then
      local module_name = file:gsub("%.lua$", "")
      local ok, err = pcall(require, "plugins." .. module_name)
      if not ok then
        vim.notify("Failed to load " .. module_name .. "\n\n" .. err, vim.log.levels.ERROR)
      else
        table.insert(all_config, err)
      end
    end
  end
  return all_config
end

local all_config = load_plugins()

---@type NvPluginSpec[]
local plugins = { -- Override plugin definition options
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
  {
    "pteroctopus/faster.nvim",
  },
  -- import all plugins from the plugins directory
  -- this is a good way to keep the init.lua file clean
}
-- merge all_config into plugins
for _, config in ipairs(all_config) do
  table.insert(plugins, config)
end
if not vim.env.DEEPSEEK_API_KEY then
  table.insert(plugins, {
    "github/copilot.vim",
    lazy = false,
    cond = function()
      return not vim.g.vscode
    end,
  })
end

return plugins
