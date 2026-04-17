local M = {}

local ns = vim.api.nvim_create_namespace("paren_wrap_preview")

local function trim(str)
  return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function collect_top_level_ops(expr)
  local ops = {}
  local i = 1
  local depth = 0
  local in_single = false
  local in_double = false
  local op_tokens = {
    "//", "**", "<<", ">>", "==", "!=", "<=", ">=",
    "+", "-", "*", "/", "%", "|", "&", "^",
    "=", ",", ":", " ",
  }
  local unmatched_openers = {}

  while i <= #expr do
    local ch = expr:sub(i, i)
    local prev = i > 1 and expr:sub(i - 1, i - 1) or ""

    if in_single then
      if ch == "'" and prev ~= "\\" then
        in_single = false
      end
      i = i + 1
    elseif in_double then
      if ch == '"' and prev ~= "\\" then
        in_double = false
      end
      i = i + 1
    else
      if ch == "'" then
        in_single = true
        i = i + 1
      elseif ch == '"' then
        in_double = true
        i = i + 1
      elseif ch == "(" or ch == "[" or ch == "{" then
        table.insert(unmatched_openers, i)
        depth = depth + 1
        i = i + 1
      elseif ch == ")" or ch == "]" or ch == "}" then
        if #unmatched_openers > 0 then
          table.remove(unmatched_openers)
        end
        depth = math.max(depth - 1, 0)
        i = i + 1
      else
        local matched = false
        for _, op in ipairs(op_tokens) do
          if expr:sub(i, i + #op - 1) == op then
            table.insert(ops, { start_col = i, end_col = i + #op - 1, depth = depth })
            i = i + #op
            matched = true
            break
          end
        end
        if not matched then
          i = i + 1
        end
      end
    end
  end

  local base_depth = depth
  local filtered = {}

  if base_depth > 0 and #unmatched_openers > 0 then
    local opener_idx = unmatched_openers[#unmatched_openers]
    table.insert(filtered, { start_col = opener_idx, end_col = opener_idx })
  end

  for _, op in ipairs(ops) do
    if op.depth == base_depth then
      table.insert(filtered, { start_col = op.start_col, end_col = op.end_col })
    end
  end

  table.sort(filtered, function(a, b)
    return a.end_col < b.end_col
  end)

  local merged = {}
  for _, op in ipairs(filtered) do
    if #merged == 0 then
      table.insert(merged, op)
    else
      local last = merged[#merged]
      if op.start_col <= last.end_col + 1 then
        merged[#merged].end_col = math.max(last.end_col, op.end_col)
      else
        table.insert(merged, op)
      end
    end
  end

  return merged
end

local function wrap_last_n_operands(expr, n)
  local source = trim(expr)
  if source == "" then
    return source
  end

  local ops = collect_top_level_ops(source)
  local operator_count = #ops
  local operand_count = operator_count + 1

  if operator_count == 0 or n >= operand_count then
    return "(" .. source .. ")"
  end

  local boundary_op = ops[operator_count - n + 1]
  local left = source:sub(1, boundary_op.end_col)
  local right = source:sub(boundary_op.end_col + 1)
  return left .. "(" .. trim(right) .. ")"
end

local function effective_distance(expr, typed_count)
  local source = trim(expr)
  if typed_count > 1 and source:sub(-1) == ")" then
    return typed_count - 1
  end
  return typed_count
end

local function parse_suffix_at_end(before_line)
  local expr, parens = before_line:match("^(.-)%.([)]*)$")
  if not expr or parens == nil then
    return nil, nil
  end
  return expr, #parens
end

local function get_expanded_before(before_line)
  local expr, count = parse_suffix_at_end(before_line)
  if not expr or trim(expr) == "" then
    return nil
  end
  local typed = math.max(count, 1)
  return wrap_last_n_operands(expr, effective_distance(expr, typed))
end

function M.expand_inline(before_line)
  return get_expanded_before(before_line)
end

function M.has_suffix_at_end(before_line)
  local expr, count = parse_suffix_at_end(before_line)
  return expr ~= nil and count ~= nil and trim(expr) ~= ""
end

function M.preview_line(line, col)
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  local expanded = get_expanded_before(before)
  if not expanded then
    return nil
  end
  return expanded .. after
end

function M.clear_preview(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function M.refresh_preview(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  M.clear_preview(bufnr)

  if vim.bo[bufnr].filetype ~= "python" then
    return
  end

  if vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if not mode:match("^[iR]") then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local preview = M.preview_line(line, col)
  if not preview or preview == line then
    return
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, col, {
    virt_text = { { " => " .. preview, "Comment" } },
    virt_text_pos = "eol",
    hl_mode = "combine",
  })
end

function M.setup()
  if M._did_setup then
    return
  end
  M._did_setup = true

  local aug = vim.api.nvim_create_augroup("ParenWrapPreview", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP", "CursorMovedI" }, {
    group = aug,
    callback = function(args)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          M.refresh_preview(args.buf)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = aug,
    callback = function(args)
      if vim.api.nvim_buf_is_valid(args.buf) then
        M.clear_preview(args.buf)
      end
    end,
  })
end

return M
