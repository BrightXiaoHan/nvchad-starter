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

local function make_codex_toggle(cmd, count)
    local Terminal = require("toggleterm.terminal").Terminal
    local codex_term = Terminal:new {
        cmd = cmd,
        direction = "vertical",
        count = count,
        size = function()
            return math.floor(vim.o.columns / 3)
        end,
        hidden = true,
    }

    return function()
        codex_term:toggle()
        -- keep the Codex terminal docked on the right
        if codex_term:is_open() then
            vim.cmd "wincmd L"
        end
    end
end

local function make_gemini_toggle()
    local Terminal = require("toggleterm.terminal").Terminal
    local gemini_term = Terminal:new {
        cmd = "gemini",
        direction = "vertical",
        count = 98,
        size = function()
            return math.floor(vim.o.columns / 3)
        end,
        hidden = true,
    }

    return function()
        gemini_term:toggle()
        if gemini_term:is_open() then
            vim.cmd "wincmd L"
        end
    end
end

local function make_kimi_toggle()
    local Terminal = require("toggleterm.terminal").Terminal
    local kimi_term = Terminal:new {
        cmd = "kimi",
        direction = "vertical",
        count = 97,
        size = function()
            return math.floor(vim.o.columns / 3)
        end,
        hidden = true,
    }

    return function()
        kimi_term:toggle()
        if kimi_term:is_open() then
            vim.cmd "wincmd L"
        end
    end
end

local function make_tab_toggle()
    -- force terminal 1 to always open in a new tab, regardless of prior state
    return function()
        require("toggleterm").toggle(1, nil, nil, "tab")
    end
end

local plugin = {
    "akinsho/toggleterm.nvim",
    config = function(_, _opts)
        require("toggleterm").setup(_opts)

        local toggle_codex = make_codex_toggle("codex", 99)
        local toggle_codex_resume = make_codex_toggle("codex resume", 96)
        local toggle_gemini = make_gemini_toggle()
        local toggle_kimi = make_kimi_toggle()
        vim.keymap.set({ "n", "t" }, "<leader>tc", toggle_codex, {
            desc = "Toggle Codex terminal",
        })
        vim.keymap.set({ "n", "t" }, "<A-l>", toggle_codex, {
            desc = "Toggle Codex terminal",
        })
        vim.keymap.set({ "n", "t" }, "<A-L>", toggle_codex_resume, {
            desc = "Toggle Codex terminal (resume)",
        })
        vim.keymap.set({ "n", "t" }, "<A-g>", toggle_gemini, {
            desc = "Toggle Gemini terminal",
        })
        vim.keymap.set({ "n", "t" }, "<A-k>", toggle_kimi, {
            desc = "Toggle Kimi terminal",
        })
    end,
    lazy = false,
    opts = opts,
    init = function()
        local toggle_tab = make_tab_toggle()
        vim.keymap.set("n", "<C-\\>", toggle_tab, {
            desc = "Toggle tab term",
        })
        vim.keymap.set("t", "<C-\\>", toggle_tab, {
            desc = "Toggle tab term",
        })
        vim.keymap.set("n", "<C-`>", toggle_tab, {
            desc = "Toggle tab term",
        })
        vim.keymap.set("t", "<C-`>", toggle_tab, {
            desc = "Toggle tab term",
        })
    end,
    cond = function()
        return not vim.g.vscode
    end,
}

return plugin
