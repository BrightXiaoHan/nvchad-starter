local plugin = {
  "mfussenegger/nvim-dap-python",
  lazy = false,
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
    require("dap-python").setup "uv"
  end,
  init = function()
    -- Debugging mappings
    vim.keymap.set({ "n", "i" }, "\\b", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", {
      desc = "Toggle breakpoint",
    })
    vim.keymap.set({ "n", "i" }, "\\c", "<cmd>lua require'dap'.continue()<CR>", {
      desc = "Start/Continue debugging",
    })
    vim.keymap.set({ "n", "i" }, "\\s", "<cmd>lua require'dap'.step_into()<CR>", {
      desc = "Step into",
    })
    vim.keymap.set({ "n", "i" }, "\\n", "<cmd>lua require'dap'.step_over()<CR>", {
      desc = "Step over",
    })
    vim.keymap.set({ "n", "i" }, "\\S", "<cmd>lua require'dap'.step_out()<CR>", {
      desc = "Step out",
    })
    vim.keymap.set({ "n", "i" }, "\\t", "<cmd>lua require'dap'.repl.toggle()<CR>", {
      desc = "Toggle REPL",
    })
    vim.keymap.set(
      { "n", "i" },
      "\\C",
      "<cmd>lua require'dap'.disconnect({ terminateDebuggee = true }); require'dap'.close()<CR>",
      {
        desc = "Terminate DAP and close UI",
      }
    )
  end,
}

return plugin
