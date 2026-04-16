local map = vim.keymap.set

map("n", ";;", "<cmd>noh<CR>", { desc = "clear highlights" })
map("n", "F", vim.lsp.buf.hover, { desc = "lsp hover" })
-- Backslash prefix: window management.
map("n", "\\v", "<cmd>vsplit<CR>", { desc = "window split vertical" })
map("n", "\\s", "<cmd>split<CR>", { desc = "window split horizontal" })
map("n", "\\x", "<cmd>close<CR>", { desc = "window close" })
map("n", "\\o", "<cmd>only<CR>", { desc = "window close others" })
map("n", "\\=", "<C-w>=", { desc = "window balance" })
map("n", "\\h", "<C-w>h", { desc = "window left" })
map("n", "\\j", "<C-w>j", { desc = "window down" })
map("n", "\\k", "<C-w>k", { desc = "window up" })
map("n", "\\l", "<C-w>l", { desc = "window right" })
map("n", "\\<Left>", "<C-w>h", { desc = "window left" })
map("n", "\\<Down>", "<C-w>j", { desc = "window down" })
map("n", "\\<Up>", "<C-w>k", { desc = "window up" })
map("n", "\\<Right>", "<C-w>l", { desc = "window right" })
map("n", "\\H", "<cmd>vertical resize -5<CR>", { desc = "window narrower" })
map("n", "\\L", "<cmd>vertical resize +5<CR>", { desc = "window wider" })
map("n", "\\J", "<cmd>resize -3<CR>", { desc = "window shorter" })
map("n", "\\K", "<cmd>resize +3<CR>", { desc = "window taller" })
map("n", "\\<S-Left>", "<cmd>vertical resize -5<CR>", { desc = "window narrower" })
map("n", "\\<S-Right>", "<cmd>vertical resize +5<CR>", { desc = "window wider" })
map("n", "\\<S-Down>", "<cmd>resize -3<CR>", { desc = "window shorter" })
map("n", "\\<S-Up>", "<cmd>resize +3<CR>", { desc = "window taller" })
map("n", "\\w", function()
  require("nvim-window").pick()
end, { desc = "window pick" })
map("n", "<leader>w", function()
  require("nvim-window").pick()
end, { desc = "pick window" })
map("v", "<C-c>", '"+y', { desc = "copy selection" })
map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>fm", function()
  require("conform").format({ lsp_fallback = true })
end, { desc = "format file" })

map("n", "<S-k>", "<C-u>", { desc = "scroll up half page" })
map("v", "<S-k>", "<C-u>", { desc = "scroll up half page" })
map("n", "<S-j>", "<C-d>", { desc = "scroll down half page" })
map("v", "<S-j>", "<C-d>", { desc = "scroll down half page" })

map("n", "<tab>", "<cmd>bnext<CR>", { desc = "next buffer" })
map("n", "<S-tab>", "<cmd>bprevious<CR>", { desc = "previous buffer" })
map("n", "<space>x", "<cmd>bd<CR>", { desc = "close buffer" })

map("n", "<leader>/", "gcc", { desc = "comment toggle", remap = true })
map("v", "<leader>/", "gc", { desc = "comment toggle", remap = true })

map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "find buffers" })
map("n", "<leader>tg", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "document symbols" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "old files" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "buffer fuzzy find" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "git status" })
map("n", "<leader>th", "<cmd>Telescope colorscheme<CR>", { desc = "themes" })
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "find files" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", { desc = "find all files" })

map("t", "<C-x>", "<C-\\><C-n>", { desc = "escape terminal mode" })
local float_term_buf = nil
local float_term_win = nil

local function centered_term_win_opts()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.8)
  local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
end

map({ "n", "t" }, "<leader><CR>", function()
  if float_term_win and vim.api.nvim_win_is_valid(float_term_win) then
    vim.api.nvim_win_close(float_term_win, true)
    float_term_win = nil
    return
  end

  if not (float_term_buf and vim.api.nvim_buf_is_valid(float_term_buf)) then
    float_term_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[float_term_buf].buflisted = false
    vim.bo[float_term_buf].bufhidden = "hide"
    vim.api.nvim_buf_call(float_term_buf, function()
      vim.fn.termopen(vim.o.shell)
    end)
  end

  float_term_win = vim.api.nvim_open_win(float_term_buf, true, centered_term_win_opts())
  vim.wo[float_term_win].number = false
  vim.wo[float_term_win].relativenumber = false
  vim.wo[float_term_win].signcolumn = "no"
  vim.cmd("startinsert")
end, { desc = "toggle centered floating terminal" })
map("n", "<leader>wK", "<cmd>WhichKey<CR>", { desc = "whichkey all keymaps" })
map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

local function add_symbols_around_selection(left_symbol, right_symbol)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local line = vim.fn.getline(start_pos[2])
  local before = string.sub(line, 1, start_pos[3] - 1)
  local selected_text = string.sub(line, start_pos[3], end_pos[3])
  local after = string.sub(line, end_pos[3] + 1)
  local trimmed_text = selected_text:match("^%s*(.-)%s*$")
  vim.fn.setline(start_pos[2], before .. left_symbol .. trimmed_text .. right_symbol .. after)
end

local function remove_pairs()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local line = vim.fn.getline(start_pos[2])
  local before = string.sub(line, 1, start_pos[3] - 1)
  local selected_text = string.sub(line, start_pos[3], end_pos[3])
  local after = string.sub(line, end_pos[3] + 1)
  local trimmed_text = selected_text:match("^%s*(.-)%s*$")
  if #trimmed_text >= 2 then
    trimmed_text = string.sub(trimmed_text, 2, #trimmed_text - 1)
  end
  vim.fn.setline(start_pos[2], before .. trimmed_text .. after)
end

map("v", "<leader>r'", remove_pairs, { desc = "unwrap selection" })
map("v", '<leader>r"', remove_pairs, { desc = "unwrap selection" })
map("v", "<leader>r]", remove_pairs, { desc = "unwrap selection" })
map("v", "<leader>r}", remove_pairs, { desc = "unwrap selection" })
map("v", "<leader>r)", remove_pairs, { desc = "unwrap selection" })
map("v", "<leader>'", function()
  add_symbols_around_selection("'", "'")
end, { desc = "wrap with quote" })
map("v", '<leader>"', function()
  add_symbols_around_selection('"', '"')
end, { desc = "wrap with double quote" })
map("v", "<leader>]", function()
  add_symbols_around_selection("[", "]")
end, { desc = "wrap with []" })
map("v", "<leader>}", function()
  add_symbols_around_selection("{", "}")
end, { desc = "wrap with {}" })
map("v", "<leader>)", function()
  add_symbols_around_selection("(", ")")
end, { desc = "wrap with ()" })

map("n", "<F5>", function()
  require("dap").continue()
end, { desc = "dap continue" })
map("n", "<F6>", function()
  require("dap").terminate()
end, { desc = "dap terminate" })
map("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "dap step over" })
map("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "dap step into" })
map("n", "<F12>", function()
  require("dap").step_out()
end, { desc = "dap step out" })
map("n", "<C-down>", function()
  require("dap").step_over()
end, { desc = "dap step over" })
map("n", "<C-right>", function()
  require("dap").step_into()
end, { desc = "dap step into" })
map("n", "<C-left>", function()
  require("dap").step_out()
end, { desc = "dap step out" })
map("n", "<Leader>b", function()
  require("dap").toggle_breakpoint()
end, { desc = "dap toggle breakpoint" })
map("n", "<Leader>B", function()
  require("dap").set_breakpoint()
end, { desc = "dap set breakpoint" })
map("n", "<Leader>lp", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { desc = "dap set logpoint" })
map("n", "<Leader>dr", function()
  require("dap").repl.open()
end, { desc = "dap open repl" })
map("n", "<Leader>dl", function()
  require("dap").run_last()
end, { desc = "dap run last" })

map("n", "<leader>ldf", "<cmd>Telescope lsp_definitions<CR>", { desc = "lsp definitions" })
map("n", "<leader>lws", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "workspace symbols" })
map("n", "<leader>lds", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "document symbols" })
map("n", "<leader>lrf", "<cmd>Telescope lsp_references<CR>", { desc = "lsp references" })
map("n", "<leader>lty", "<cmd>Telescope lsp_type_definitions<CR>", { desc = "type definitions" })
map("n", "<leader>lip", "<cmd>Telescope lsp_implementations<CR>", { desc = "implementations" })
map("n", "<leader>lic", "<cmd>Telescope lsp_incoming_calls<CR>", { desc = "incoming calls" })
map("n", "<leader>loc", "<cmd>Telescope lsp_outgoing_calls<CR>", { desc = "outgoing calls" })

map("n", "<space><Tab>", function()
  if vim.bo.filetype == "oil" then
    vim.cmd("bd")
  else
    require("oil").toggle_float()
  end
end, { desc = "toggle oil" })

local diagnostics_enabled = {}
map("n", "<space>dg", function()
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
end, { desc = "toggle diagnostics" })

map("n", "<space>f", vim.diagnostic.open_float, { desc = "open diagnostics float" })
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "code action" })

vim.keymap.set("v", "<S-C>", '"+y', { noremap = true })
vim.keymap.set("n", "<sc-v>", 'l"+P', { noremap = true })
vim.keymap.set("v", "<sc-v>", '"+P', { noremap = true })
vim.keymap.set("c", "<sc-v>", '<C-o>l<C-o>"+<C-o>P<C-o>l', { noremap = true })
vim.keymap.set("i", "<sc-v>", '<ESC>l"+Pli', { noremap = true })
vim.keymap.set("t", "<sc-v>", '<C-\\><C-n>"+Pi', { noremap = true })

map("n", "<C-q>", function()
  local current_file = vim.fn.expand("%")
  local width = vim.o.columns * 0.5
  local height = vim.o.lines * 0.5
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = math.ceil(width),
    height = math.ceil(height),
    col = 1,
    row = 1,
    border = "rounded",
  })
  vim.fn.termopen("easy " .. current_file)
end, { desc = "run source code" })

map("n", "<leader>fy", function()
  local width = vim.o.columns * 0.5
  local height = vim.o.lines * 0.5
  local word = vim.fn.expand("<cword>")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = math.ceil(width),
    height = math.ceil(height),
    col = 0,
    row = 1,
    border = "rounded",
  })
  vim.fn.termopen("fanyi " .. word)
end, { desc = "translate word" })

map("n", "<leader>tp", function()
  local width = 80
  local height = 24
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_open_win(buf, true, {
    style = "minimal",
    relative = "win",
    width = math.ceil(width),
    height = math.ceil(height),
    row = 0,
    col = 1200,
    border = "rounded",
  })
  vim.fn.termopen("btop")
end, { desc = "run btop" })
