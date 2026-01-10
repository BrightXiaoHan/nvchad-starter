local autocmd = vim.api.nvim_create_autocmd

-- user event that loads after UIEnter + only if file buf is there
autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("NvFilePost", { clear = true }),
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })

        if not vim.g.ui_entered and args.event == "UIEnter" then
            vim.g.ui_entered = true
        end

        if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
            vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })
            vim.api.nvim_del_augroup_by_name "NvFilePost"

            vim.schedule(function()
                vim.api.nvim_exec_autocmds("FileType", {})

                if vim.g.editorconfig then
                    require("editorconfig").config(args.buf)
                end
            end)
        end
    end,
})

autocmd({ "BufLeave", "BufWinLeave", "BufUnload", "BufDelete", "QuitPre" }, {
    group = vim.api.nvim_create_augroup("AutoSaveOnExit", { clear = true }),
    callback = function()
        if vim.bo.modified and vim.bo.modifiable and vim.bo.buftype == "" then
            vim.cmd("silent update")
        end
    end,
})

-- Auto reload file when external changes detected
vim.o.autoread = true
vim.o.updatetime = 250
autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = vim.api.nvim_create_augroup("AutoReloadOnFocus", { clear = true }),
    callback = function()
        if vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
})

-- Notify when file changed
autocmd("FileChangedShellPost", {
    group = vim.api.nvim_create_augroup("FileChangedNotify", { clear = true }),
    callback = function()
        vim.notify("File changed on disk. Reloaded.", vim.log.levels.INFO)
    end,
})
