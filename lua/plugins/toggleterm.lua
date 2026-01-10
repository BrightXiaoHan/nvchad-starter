-- if win32, use pwsh
-- otherwise, use fish
if vim.fn.has "win32" == 1 then
    SHELL = "pwsh"
else
    SHELL = "fish"
end

local opts = {
    shell = SHELL,
    highlights = {
        NormalFloat = {
            guibg = "#0d1117",
        },
        FloatBorder = {
            guibg = "#0d1117",
            guifg = "#0d1117",
        },
    },
}

-- AI terminals state management (mutually exclusive)
local ai_terms = {}
local function ai_term_size()
    return math.floor(vim.o.columns / 3)
end

local function hide_other_ai_terms(current_name)
    for name, state in pairs(ai_terms) do
        if name ~= current_name and state.term and state.term:is_open() then
            state.term:close()
        end
    end
end

local function get_or_create_ai_term(name, cmd, count)
    local Terminal = require("toggleterm.terminal").Terminal
    local state = ai_terms[name]

    -- Handle codex special case: different cmd means recreate terminal
    if state and state.term and state.cmd ~= cmd then
        if state.term:is_open() then
            return state.term
        end
        state.term:shutdown()
        state.term = nil
    end

    if not state or not state.term then
        ai_terms[name] = {
            term = Terminal:new {
                cmd = cmd,
                direction = "float",
                count = count,
                hidden = true,
                float_opts = {
                    border = "none",
                    width = function()
                        return math.floor(vim.o.columns / 2)
                    end,
                    height = function()
                        return vim.o.lines - 4
                    end,
                    col = function()
                        return vim.o.columns -- right aligned
                    end,
                    row = 0,
                },
            },
            cmd = cmd,
        }
    end
    return ai_terms[name].term
end

local function make_ai_toggle(name, cmd, count)
    return function()
        local term = get_or_create_ai_term(name, cmd, count)

        if term:is_open() then
            term:close()
            return
        end

        hide_other_ai_terms(name)
        term:open()
    end
end

local function make_float_bottom_toggle()
    local Terminal = require("toggleterm.terminal").Terminal
    local bottom_term = nil

    return function()
        if not bottom_term then
            bottom_term = Terminal:new {
                cmd = SHELL,
                direction = "float",
                count = 1,
                hidden = true,
                float_opts = {
                    border = "none",
                    width = function()
                        return vim.o.columns
                    end,
                    height = function()
                        return math.floor((vim.o.lines - 2) * 2 / 3)
                    end,
                    col = 0,
                    row = function()
                        return math.floor((vim.o.lines - 2) / 3)
                    end,
                },
            }
        end
        bottom_term:toggle()
    end
end

local plugin = {
    "akinsho/toggleterm.nvim",
    config = function(_, _opts)
        require("toggleterm").setup(_opts)

        local toggle_codex = make_ai_toggle("codex", "codex", 99)
        local toggle_codex_resume = make_ai_toggle("codex", "codex resume", 99)
        local toggle_gemini = make_ai_toggle("gemini", "gemini", 98)
        local toggle_kimi = make_ai_toggle("kimi", "kimi", 97)
        local toggle_claude = make_ai_toggle("claude", "claude", 96)
        local toggle_opencode = make_ai_toggle("opencode", "opencode", 95)
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
        vim.keymap.set({ "n", "t" }, "<A-c>", toggle_claude, {
            desc = "Toggle Claude Code terminal",
        })
        vim.keymap.set({ "n", "t" }, "<A-p>", toggle_opencode, {
            desc = "Toggle OpenCode terminal",
        })
    end,
    lazy = false,
    opts = opts,
    init = function()
        local toggle_tab = make_float_bottom_toggle()
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
