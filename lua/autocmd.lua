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
    callback = function(args)
        local function save_buf(buf)
            if not buf or not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
            local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = buf })
            local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })

            if modified and modifiable and buftype == "" then
                pcall(vim.api.nvim_buf_call, buf, function()
                    vim.cmd "silent update"
                end)
            end
        end

        if args.event == "QuitPre" then
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                save_buf(buf)
            end
        else
            save_buf(args.buf)
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
