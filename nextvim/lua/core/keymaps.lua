local map = vim.keymap.set

local function ts_fold_range()
  local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
  if not ok or not node then
    return nil, nil
  end
  local targets = {
    function_declaration = true,
    function_definition = true,
    method_definition = true,
    class_definition = true,
    if_statement = true,
    for_statement = true,
    while_statement = true,
    try_statement = true,
    with_statement = true,
  }
  while node do
    if targets[node:type()] then
      local srow, _, erow, _ = node:range()
      if erow > srow then
        return srow + 1, erow + 1
      end
    end
    node = node:parent()
  end
  return nil, nil
end

local function smart_close_fold()
  pcall(vim.cmd, "normal! zc")
  if vim.fn.foldclosed(vim.fn.line(".")) ~= -1 then
    return
  end
  local sline, eline = ts_fold_range()
  if not sline or not eline then
    vim.notify("No fold", vim.log.levels.INFO)
    return
  end
  vim.cmd(string.format("%d,%dfold", sline, eline))
  pcall(vim.cmd, "normal! zc")
end

map("n", ";;", "<cmd>noh<CR>", { desc = "clear highlights" })
map("n", "F", vim.lsp.buf.hover, { desc = "lsp hover" })
map("n", "zc", smart_close_fold, { desc = "smart close fold" })
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
-- Extra short LSP mappings.
map("n", "gd", vim.lsp.buf.definition, { desc = "goto definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "goto declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "goto references" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "goto implementation" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "goto type definition" })

-- Persistent bookmarks: add/delete/list-jump/toggle/next/prev.
vim.fn.sign_define("UserBookmarkSign", { text = "●", texthl = "DiagnosticHint" })
local bookmark_file = vim.fn.stdpath("data") .. "/bookmarks.json"
local bookmarks = {} -- [abs_path] = { [line] = true }

local function normalize_path(path)
  if not path or path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":p")
end

local function save_bookmarks()
  local serializable = {}
  for path, lines in pairs(bookmarks) do
    local arr = {}
    for line, marked in pairs(lines) do
      if marked then
        table.insert(arr, line)
      end
    end
    table.sort(arr)
    if #arr > 0 then
      serializable[path] = arr
    end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(bookmark_file, ":h"), "p")
  vim.fn.writefile({ vim.json.encode(serializable) }, bookmark_file)
end

local function load_bookmarks()
  local ok, content = pcall(vim.fn.readfile, bookmark_file)
  if not ok or not content or #content == 0 then
    return
  end
  local data_ok, data = pcall(vim.json.decode, table.concat(content, "\n"))
  if not data_ok or type(data) ~= "table" then
    return
  end
  for path, lines in pairs(data) do
    local abs = normalize_path(path)
    if abs and type(lines) == "table" then
      bookmarks[abs] = {}
      for _, line in ipairs(lines) do
        local n = tonumber(line)
        if n and n > 0 then
          bookmarks[abs][n] = true
        end
      end
    end
  end
end

local function sign_id(bufnr, line)
  return bufnr * 100000 + line
end

local function sync_signs_for_buf(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
  vim.fn.sign_unplace("user_bookmarks", { buffer = bufnr })
  if not path or not bookmarks[path] then
    return
  end
  for line, marked in pairs(bookmarks[path]) do
    if marked then
      vim.fn.sign_place(sign_id(bufnr, line), "user_bookmarks", "UserBookmarkSign", bufnr, { lnum = line, priority = 20 })
    end
  end
end

local function ensure_bucket(path)
  if not bookmarks[path] then
    bookmarks[path] = {}
  end
  return bookmarks[path]
end

local function add_bookmark()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if not path then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local bucket = ensure_bucket(path)
  if bucket[line] then
    vim.notify("该行已存在书签", vim.log.levels.INFO)
    return
  end
  bucket[line] = true
  sync_signs_for_buf(bufnr)
  save_bookmarks()
  vim.notify("已添加书签", vim.log.levels.INFO)
end

local function delete_bookmark()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if not path then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local bucket = ensure_bucket(path)
  if not bucket[line] then
    vim.notify("当前行没有书签", vim.log.levels.INFO)
    return
  end
  bucket[line] = nil
  if vim.tbl_isempty(bucket) then
    bookmarks[path] = nil
  end
  sync_signs_for_buf(bufnr)
  save_bookmarks()
  vim.notify("已删除书签", vim.log.levels.INFO)
end

local function file_line_text(path, line)
  local bufnr = vim.fn.bufnr(path, false)
  if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
    return (vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or "")
  end
  if vim.fn.filereadable(path) == 1 then
    local lines = vim.fn.readfile(path)
    return lines[line] or ""
  end
  return ""
end

local function list_bookmarks()
  local items = {}
  for path, bucket in pairs(bookmarks) do
    for line, marked in pairs(bucket) do
      if marked then
        local text = file_line_text(path, line)
        table.insert(items, {
          path = path,
          line = line,
          label = string.format("%s:%d  %s", vim.fn.fnamemodify(path, ":~:."), line, vim.trim(text)),
        })
      end
    end
  end
  if #items == 0 then
    vim.notify("暂无书签", vim.log.levels.INFO)
    return
  end

  table.sort(items, function(a, b)
    if a.path == b.path then
      return a.line < b.line
    end
    return a.path < b.path
  end)

  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if has_telescope then
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local action_set = require("telescope.actions.set")

    pickers
      .new({}, {
        prompt_title = "Bookmarks",
        layout_strategy = "horizontal",
        sorting_strategy = "ascending",
        previewer = true,
        preview_cutoff = 0,
        layout_config = {
          width = 0.95,
          height = 0.9,
          prompt_position = "top",
          horizontal = { preview_width = 0.55 },
        },
        finder = finders.new_table({
          results = items,
          entry_maker = function(item)
            return {
              value = item,
              display = item.label,
              ordinal = item.label,
              filename = item.path,
              lnum = item.line,
              col = 1,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.grep_previewer({}),
        attach_mappings = function(prompt_bufnr, _)
          local function safe_select_or_close()
            local ok, selection = pcall(action_state.get_selected_entry)
            if not ok or not selection or not selection.value then
              actions.close(prompt_bufnr)
              return
            end
            actions.close(prompt_bufnr)
            local choice = selection.value
            vim.cmd("edit " .. vim.fn.fnameescape(choice.path))
            vim.api.nvim_win_set_cursor(0, { choice.line, 0 })
          end

          actions.select_default:replace(function()
            safe_select_or_close()
          end)
          action_set.select:replace(function()
            safe_select_or_close()
          end)
          return true
        end,
      })
      :find()
    return
  end

  vim.ui.select(items, {
    prompt = "跳转书签",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(choice.path))
    vim.api.nvim_win_set_cursor(0, { choice.line, 0 })
  end)
end

local function collect_sorted_bookmarks()
  local items = {}
  for path, bucket in pairs(bookmarks) do
    for line, marked in pairs(bucket) do
      if marked then
        table.insert(items, { path = path, line = line })
      end
    end
  end
  table.sort(items, function(a, b)
    if a.path == b.path then
      return a.line < b.line
    end
    return a.path < b.path
  end)
  return items
end

local function goto_bookmark(item)
  if not item then
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(item.path))
  vim.api.nvim_win_set_cursor(0, { item.line, 0 })
end

local function toggle_bookmark()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if not path then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local bucket = ensure_bucket(path)
  if bucket[line] then
    delete_bookmark()
  else
    add_bookmark()
  end
end

local function jump_bookmark(direction)
  local items = collect_sorted_bookmarks()
  if #items == 0 then
    vim.notify("暂无书签", vim.log.levels.INFO)
    return
  end
  local cur_path = normalize_path(vim.api.nvim_buf_get_name(0)) or ""
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local index = nil
  for i, item in ipairs(items) do
    if item.path == cur_path and item.line == cur_line then
      index = i
      break
    end
  end

  local target
  if direction > 0 then
    if index then
      target = items[(index % #items) + 1]
    else
      target = items[1]
      for _, item in ipairs(items) do
        if item.path > cur_path or (item.path == cur_path and item.line > cur_line) then
          target = item
          break
        end
      end
    end
  else
    if index then
      target = items[((index - 2 + #items) % #items) + 1]
    else
      target = items[#items]
      for i = #items, 1, -1 do
        local item = items[i]
        if item.path < cur_path or (item.path == cur_path and item.line < cur_line) then
          target = item
          break
        end
      end
    end
  end
  goto_bookmark(target)
end

load_bookmarks()
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("UserBookmarkSigns", { clear = true }),
  callback = function(args)
    sync_signs_for_buf(args.buf)
  end,
})

map("n", "<leader>ma", add_bookmark, { desc = "bookmark add current line" })
map("n", "<leader>md", delete_bookmark, { desc = "bookmark delete current line" })
map("n", "<leader>mm", list_bookmarks, { desc = "bookmark list and jump" })
map("n", "mA", toggle_bookmark, { desc = "bookmark toggle current line" })
map("n", "m]", function()
  jump_bookmark(1)
end, { desc = "bookmark next" })
map("n", "m[", function()
  jump_bookmark(-1)
end, { desc = "bookmark prev" })

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
