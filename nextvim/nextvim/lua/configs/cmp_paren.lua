local M = {}

local ns = vim.api.nvim_create_namespace("paren_wrap_preview")

-- Active preview state
M._state = nil -- { bufnr, row, original_line, preview_line, cursor_col }

local bracket_pairs = {
  [")"] = { open = "(", close = ")" },
  ["]"] = { open = "[", close = "]" },
  ["}"] = { open = "{", close = "}" },
}

local function trim(str)
  return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Collect top-level operator positions in an expression.
--- Handles nested brackets, string literals, and unmatched openers.
--- Returns a list of merged operator spans: { start_col, end_col }
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

  -- Use the final nesting depth as the "base" level.
  -- When there are unmatched openers (e.g. "func(a+b+c"), we treat the
  -- content after the last opener as the expression to operate on.
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

  -- Merge adjacent/overlapping operator spans (e.g. "a + b" has space+plus+space)
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

--- Wrap the last N operands with the given bracket pair.
local function wrap_last_n_operands(expr, n, pair)
  local source = trim(expr)
  if source == "" then
    return source
  end

  local ops = collect_top_level_ops(source)
  local operator_count = #ops
  local operand_count = operator_count + 1

  if operator_count == 0 or n >= operand_count then
    return pair.open .. source .. pair.close
  end

  local boundary_op = ops[operator_count - n + 1]
  local left = source:sub(1, boundary_op.end_col)
  local right = trim(source:sub(boundary_op.end_col + 1))
  return left .. pair.open .. right .. pair.close
end

--- Parse the suffix trigger pattern from text before the cursor.
--- Matches: <expression> . <one-or-more-identical-closing-brackets>
--- Returns: expr, bracket_count, bracket_pair  OR  nil, nil, nil
local function parse_suffix(before_cursor)
  local expr, dot_brackets = before_cursor:match("^(.-)(%.[%)%]%}]+)$")
  if not expr or not dot_brackets then
    return nil, nil, nil
  end

  local brackets = dot_brackets:sub(2) -- strip the leading dot
  local first = brackets:sub(1, 1)

  -- All closing brackets must be the same type
  for i = 2, #brackets do
    if brackets:sub(i, i) ~= first then
      return nil, nil, nil
    end
  end

  local pair = bracket_pairs[first]
  if not pair then
    return nil, nil, nil
  end

  if trim(expr) == "" then
    return nil, nil, nil
  end

  return expr, #brackets, pair
end

--- Compute the preview for a full line given the cursor column (0-indexed byte offset).
--- Returns: preview_line, cursor_col_for_confirm  OR  nil, nil
function M.preview_line(line, col)
  local before = line:sub(1, col)
  local after = line:sub(col + 1)

  local expr, count, pair = parse_suffix(before)
  if not expr then
    return nil, nil
  end

  local wrapped = wrap_last_n_operands(expr, count, pair)
  return wrapped .. after, #wrapped
end

function M.is_active()
  return M._state ~= nil
end

function M.clear_preview(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr or 0, ns, 0, -1)
  M._state = nil
end

function M.refresh_preview(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  M.clear_preview(bufnr)

  if vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if not mode:match("^[iR]") then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local preview, cursor_col = M.preview_line(line, col)
  if not preview or preview == line then
    return
  end

  -- Overlay the preview on top of the actual buffer line.
  -- Pad with spaces so the overlay fully covers the original text.
  local display = preview
  if #preview < #line then
    display = preview .. string.rep(" ", #line - #preview)
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, 0, {
    virt_text = { { display, "Comment" } },
    virt_text_pos = "overlay",
    priority = 1000,
  })

  M._state = {
    bufnr = bufnr,
    row = row,
    original_line = line,
    preview_line = preview,
    cursor_col = cursor_col,
  }
end

--- Confirm the preview: replace the buffer line and position cursor after the closing bracket.
--- Returns true if a preview was confirmed, false otherwise.
function M.confirm()
  if not M._state then
    return false
  end

  local s = M._state
  if not vim.api.nvim_buf_is_valid(s.bufnr) then
    M._state = nil
    return false
  end

  -- Replace the line with the computed preview
  vim.api.nvim_buf_set_lines(s.bufnr, s.row - 1, s.row, false, { s.preview_line })
  -- Place cursor right after the closing bracket
  vim.api.nvim_win_set_cursor(0, { s.row, s.cursor_col })

  M.clear_preview(s.bufnr)
  return true
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

-- Expose internals for testing
M._parse_suffix = parse_suffix
M._wrap_last_n_operands = wrap_last_n_operands
M._collect_top_level_ops = collect_top_level_ops

return M
