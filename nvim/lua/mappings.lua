local map = vim.keymap.set
map("n", ";;", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "\\v", "<cmd>vsplit<CR>", { desc = "split vertically" })
map("n", "\\h", "<cmd>split<CR>", { desc = "split horizontally" })

map("n", "<leader>w", "<cmd>lua require('nvim-window').pick()<CR>", { desc = "file quit" })
map("v", "<C-c>", ":y+<CR>", { desc = "file copy whole" })
map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

map("n", "<leader>fm", function()
    require("conform").format { lsp_fallback = true }
end, { desc = "format files" })

-- global lsp mappings
vim.keymap.set("n", "<S-Up>", "<C-u>", { desc = "scroll up half page" })
vim.keymap.set("v", "<S-Up>", "<C-u>", { desc = "scroll up half page" })
vim.keymap.set("n", "<S-k>", "<C-u>", { desc = "scroll up half page" })
vim.keymap.set("v", "<S-k>", "<C-u>", { desc = "scroll up half page" })

vim.keymap.set("n", "<S-Down>", "<C-d>", { desc = "scroll down half page" })
vim.keymap.set("v", "<S-Down>", "<C-d>", { desc = "scroll down half page" })
vim.keymap.set("n", "<S-j>", "<C-d>", { desc = "scroll down half page" })
vim.keymap.set("v", "<S-j>", "<C-d>", { desc = "scroll down half page" })

-- tabufline
-- map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

map("n", "<tab>", function()
    require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
    require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<space>x", function()
    require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

map("n", "\\x", function()
    require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })
-- Comment
map("n", "<leader>/", "gcc", { desc = "comment toggle", remap = true })
map("v", "<leader>/", "gc", { desc = "comment toggle", remap = true })
-- map("n","<space>ds","<cmd>Telescope diagnostics<CR>", { desc = "telescope diagnostics" })

-- telescope
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>tg", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "telescope ctags" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })
map("n", "<leader>th", "<cmd>Telescope themes<CR>", { desc = "telescope nvchad themes" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "telescope find all files" }
)

-- terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- toggleable

map({ "n", "t" }, "<leader><CR>", function()
    require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
    vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "whichkey query lookup" })

-- blankline
map("n", "<leader>cc", function()
    local config = { scope = {} }
    config.scope.exclude = { language = {}, node_type = {} }
    config.scope.include = { node_type = {} }
    local node = require("ibl.scope").get(vim.api.nvim_get_current_buf(), config)

    if node then
        local start_row, _, end_row, _ = node:range()
        if start_row ~= end_row then
            vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { start_row + 1, 0 })
            vim.api.nvim_feedkeys("_", "n", true)
        end
    end
end, { desc = "blankline jump to current context" })

-- add yours here
-- map("i", ";;", "<ESC>")


map("n", "<C-q>", function()
    local current_file = vim.fn.expand('%')

    local width = vim.o.columns * 0.5
    local height = vim.o.lines * 0.5
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        width = math.ceil(width),
        height = math.ceil(height),
        col = 1,
        row = 1,
        border = 'rounded'
    })
    vim.fn.termopen('easy ' .. current_file)
end, { desc = "run source code" })

map('n', '<leader>fy', function()
    local width = vim.o.columns * 0.5
    local height = vim.o.lines * 0.5
    local word = vim.fn.expand("<cword>")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        width = math.ceil(width),
        height = math.ceil(height),
        col = 0,
        row = 1,
        border = 'rounded'
    })
    -- vim.fn.termopen('fanyi -S ' .. vim.fn.expand('<cword>'))
    vim.fn.termopen('fanyi ' .. word)
end, { desc = "fanyi selected word" })

map('n', '<leader>tp', function()
    local width = 80
    local height = 24
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_open_win(buf, true, {
        style = 'minimal',
        relative = 'win',
        width = math.ceil(width),
        height = math.ceil(height),
        row = 0,
        col = 1200,
        border = 'rounded'
    })
    vim.fn.termopen('btop')
end, { desc = "run btop" })

function AddSymbolsAroundSelection(left_symbol, right_symbol)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- è·åéä¸­çææ¬
    local line = vim.fn.getline(start_line)
    local before = string.sub(line, 1, start_col - 1)
    local selected_text = string.sub(line, start_col, end_col)
    local after = string.sub(line, end_col + 1)

    -- å»æååçç©ºç½å­ç¬¦
    local trimmed_text = selected_text:match('^%s*(.-)%s*$')

    -- æ¿æ¢è¡
    local new_line = before .. left_symbol .. trimmed_text .. right_symbol .. after
    vim.fn.setline(start_line, new_line)
end

function RemovePairs(left_symbol, right_symbol)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    local line = vim.fn.getline(start_line)
    local before = string.sub(line, 1, start_col - 1)
    local selected_text = string.sub(line, start_col, end_col)
    local after = string.sub(line, end_col + 1)

    local trimmed_text = selected_text:match('^%s*(.-)%s*$')
    trimmed_text = string.sub(trimmed_text, 2, string.len(trimmed_text) - 1)
    local new_line = before .. trimmed_text .. after
    vim.fn.setline(start_line, new_line)
end

map('v', "<leader>r\'", [[:lua RemovePairs('\'', '\'')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r\"", [[:lua RemovePairs('"', '"')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r]", [[:lua RemovePairs('[', ']')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r[", [[:lua RemovePairs('[', ']')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r}", [[:lua RemovePairs('{', '}')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r{", [[:lua RemovePairs('{', '}')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r)", [[:lua RemovePairs('(', ')')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })
map('v', "<leader>r(", [[:lua RemovePairs('(', ')')<CR>]],
    { noremap = true, silent = true, desc = "Decouple with double symbol" })

map('v', "<leader>\'", [[:lua AddSymbolsAroundSelection('\'', '\'')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>\"", [[:lua AddSymbolsAroundSelection('"', '"')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>]", [[:lua AddSymbolsAroundSelection('[', ']')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>[", [[:lua AddSymbolsAroundSelection('[', ']')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>}", [[:lua AddSymbolsAroundSelection('{', '}')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>{", [[:lua AddSymbolsAroundSelection('{', '}')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>)", [[:lua AddSymbolsAroundSelection('(', ')')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })
map('v', "<leader>(", [[:lua AddSymbolsAroundSelection('(', ')')<CR>]],
    { noremap = true, silent = true, desc = "Wrap with double symbol" })

-- DAP
map('n', '<F5>', [[<cmd>lua require('dap').continue()<CR>]], { noremap = true, silent = true, desc = "continue" })
map('n', '<F6>', [[<cmd>lua require('dap').terminate()<CR>]], { noremap = true, silent = true, desc = "terminate" })
map('n', '<F10>', [[<cmd>lua require('dap').step_over()<CR>]], { noremap = true, silent = true, desc = "step_over" })
map('n', '<C-down>', [[<cmd>lua require('dap').step_over()<CR>]], { noremap = true, silent = true, desc = "step_over" })
map('n', '<F11>', [[<cmd>lua require('dap').step_into()<CR>]], { noremap = true, silent = true, desc = "step_into" })
map('n', '<C-right>', [[<cmd>lua require('dap').step_into()<CR>]], { noremap = true, silent = true, desc = "step_into" })
map('n', '<F12>', [[<cmd>lua require('dap').step_out()<CR>]], { noremap = true, silent = true, desc = "step_out" })
map('n', '<C-left>', [[<cmd>lua require('dap').step_out()<CR>]], { noremap = true, silent = true, desc = "step_out" })
map('n', '<Leader>b', [[<cmd>lua require('dap').toggle_breakpoint()<CR>]],
    { noremap = true, silent = true, desc = "toggle_breakpoint" })
map('n', '<Leader>B', [[<cmd>lua require('dap').set_breakpoint()<CR>]],
    { noremap = true, silent = true, desc = "set_breakpoint" })
map('n', '<Leader>lp', [[<cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>]],
    { noremap = true, silent = true, desc = "set_log_point_breakpoint" })
map('n', '<Leader>dr', [[<cmd>lua require('dap').repl.open()<CR>]], { noremap = true, silent = true, desc = "repl_open" })
map('n', '<Leader>dl', [[<cmd>lua require('dap').run_last()<CR>]], { noremap = true, silent = true, desc = "run_last" })
map({ 'n', 'v' }, '<Leader>dh', [[<cmd>lua require('dap.ui.widgets').hover()<CR>]],
    { noremap = true, silent = true, desc = "hover" })
map({ 'n', 'v' }, '<Leader>dp', [[<cmd>lua require('dap.ui.widgets').preview()<CR>]],
    { noremap = true, silent = true, desc = "preview" })
map('n', '<Leader>df', [[<cmd>lua local widgets = require('dap.ui.widgets'); widgets.centered_float(widgets.frames)<CR>]],
    { noremap = true, silent = true, desc = "centered_float_frames" })
map('n', '<Leader>ds', [[<cmd>lua local widgets = require('dap.ui.widgets'); widgets.centered_float(widgets.scopes)<CR>]],
    { noremap = true, silent = true, desc = "centered_float_scopes" })

map('n', '<Leader>ldf', [[<cmd>Telescope lsp_definitions<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_definitions" })
map('n', 'gd', [[<cmd>Telescope lsp_definitions<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_definitions" })
map('n', '<Leader>lws', [[<cmd>Telescope lsp_dynamic_workspace_symbols<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_dynamic_workspace_symbols" })
map('n', '<Leader>lds', [[<cmd>Telescope lsp_document_symbols<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_document_symbols" })
map('n', '<Leader>lip', [[<cmd>Telescope lsp_implementations<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_implementations" })
map('n', '<Leader>lic', [[<cmd>Telescope lsp_incoming_calls<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_incoming_calls" })
map('n', '<Leader>loc', [[<cmd>Telescope lsp_outgoing_calls<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_outgoing_calls" })
map('n', '<Leader>lrf', [[<cmd>Telescope lsp_references<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_references" })
map('n', '<Leader>lty', [[<cmd>Telescope lsp_type_definitions<CR>]],
    { noremap = true, silent = true, desc = "Telescope lsp_type_definitions" })
vim.keymap.set('n', '<space><Tab>', function()
    -- 如果当前 buffer 是 oil 的话就关闭，否则打开
    if vim.bo.filetype == 'oil' then
        vim.cmd('bd') -- 或者 :close，根据你的窗口管理方式决定
    else
        require('oil').toggle_float()
    end
end, { desc = 'Toggle oil.nvim', noremap = true, silent = true })

local diagnostics_enabled = {}

function ToggleDiagnostics()
    local bufnr = vim.api.nvim_get_current_buf()
    if diagnostics_enabled[bufnr] == nil then
        diagnostics_enabled[bufnr] = true
    end

    if diagnostics_enabled[bufnr] then
        vim.diagnostic.disable(bufnr)
        diagnostics_enabled[bufnr] = false
        vim.notify("Diagnostics disabled", vim.log.levels.INFO)
    else
        vim.diagnostic.enable(bufnr)
        diagnostics_enabled[bufnr] = true
        vim.notify("Diagnostics enabled", vim.log.levels.INFO)
    end
end

vim.keymap.set("n", "<space>dg", ToggleDiagnostics, { desc = "Toggle LSP diagnostics" })
vim.keymap.set("n", "<space>f", [[<cmd>lua vim.diagnostic.open_float()<CR>]], { desc = "Toggle LSP diagnostics" })
