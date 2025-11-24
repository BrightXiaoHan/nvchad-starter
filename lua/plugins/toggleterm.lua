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

local function make_codex_toggle()
    local Terminal = require("toggleterm.terminal").Terminal
    local codex_term = Terminal:new {
        cmd = "codex",
        direction = "vertical",
        count = 99,
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

        local toggle_codex = make_codex_toggle()
        vim.keymap.set({ "n", "t" }, "<leader>tc", toggle_codex, {
            desc = "Toggle Codex terminal",
        })
        vim.keymap.set({ "n", "t" }, "<A-l>", toggle_codex, {
            desc = "Toggle Codex terminal",
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
