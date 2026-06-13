local function load_plugins()
  local all_config = {}
  local plugin_dir = vim.fn.stdpath "config" .. "/lua/plugins"
  local files = vim.fn.readdir(plugin_dir)

  table.sort(files)

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

local plugins = {
  { "nvim-tree/nvim-web-devicons" },
  {
    "nvchad/ui",
    config = function()
      require "nvchad"
    end,
  },
  {
    "nvchad/base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },
  "nvchad/volt",
}

for _, config in ipairs(all_config) do
  table.insert(plugins, config)
end

return plugins
