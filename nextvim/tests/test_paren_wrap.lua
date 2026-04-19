#!/usr/bin/env -S nvim --headless -u NONE -l
-- Run: nvim --headless -u NONE -l tests/test_paren_wrap.lua

-- Set up package path so we can require the module
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local root = script_dir .. "../"
package.path = root .. "lua/?.lua;" .. root .. "lua/?/init.lua;" .. package.path

local paren = require("configs.cmp_paren")

local pass_count = 0
local fail_count = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    pass_count = pass_count + 1
    io.write("  PASS: " .. name .. "\n")
  else
    fail_count = fail_count + 1
    io.write("  FAIL: " .. name .. " -- " .. tostring(err) .. "\n")
  end
end

local function eq(got, expected, label)
  if got ~= expected then
    error(string.format(
      "%sexpected %s, got %s",
      label and (label .. ": ") or "",
      vim.inspect(expected),
      vim.inspect(got)
    ))
  end
end

-- ── parse_suffix ──────────────────────────────────────────────────────

io.write("\n=== parse_suffix ===\n")

test("simple .)", function()
  local expr, count, pair = paren._parse_suffix("a+b+c.)")
  eq(expr, "a+b+c")
  eq(count, 1)
  eq(pair.open, "(")
  eq(pair.close, ")")
end)

test("double .))", function()
  local expr, count, pair = paren._parse_suffix("a+b+c.))")
  eq(expr, "a+b+c")
  eq(count, 2)
  eq(pair.open, "(")
end)

test("triple .)))", function()
  local expr, count = paren._parse_suffix("a+b+c+d.)))")
  eq(expr, "a+b+c+d")
  eq(count, 3)
end)

test("square bracket .]", function()
  local expr, count, pair = paren._parse_suffix("a+b.]")
  eq(expr, "a+b")
  eq(count, 1)
  eq(pair.open, "[")
  eq(pair.close, "]")
end)

test("curly bracket .}", function()
  local expr, count, pair = paren._parse_suffix("a+b.}")
  eq(expr, "a+b")
  eq(count, 1)
  eq(pair.open, "{")
  eq(pair.close, "}")
end)

test("double square .]]", function()
  local expr, count, pair = paren._parse_suffix("a+b+c.]]")
  eq(expr, "a+b+c")
  eq(count, 2)
  eq(pair.open, "[")
end)

test("mixed brackets return nil", function()
  local expr = paren._parse_suffix("a+b.)}")
  eq(expr, nil)
end)

test("no dot returns nil", function()
  local expr = paren._parse_suffix("a+b+c)")
  eq(expr, nil)
end)

test("empty expr returns nil", function()
  local expr = paren._parse_suffix(".)")
  eq(expr, nil)
end)

test("whitespace-only expr returns nil", function()
  local expr = paren._parse_suffix("   .)")
  eq(expr, nil)
end)

test("dot in middle of expression", function()
  local expr, count, pair = paren._parse_suffix("a.b+c.)")
  eq(expr, "a.b+c")
  eq(count, 1)
  eq(pair.open, "(")
end)

test("no brackets after dot returns nil", function()
  local expr = paren._parse_suffix("a+b.")
  eq(expr, nil)
end)

-- ── wrap_last_n_operands ──────────────────────────────────────────────

io.write("\n=== wrap_last_n_operands ===\n")

local PP = { open = "(", close = ")" }
local SQ = { open = "[", close = "]" }
local CU = { open = "{", close = "}" }

test("wrap 1 operand: a+b+c", function()
  eq(paren._wrap_last_n_operands("a+b+c", 1, PP), "a+b+(c)")
end)

test("wrap 2 operands: a+b+c", function()
  eq(paren._wrap_last_n_operands("a+b+c", 2, PP), "a+(b+c)")
end)

test("wrap all 3 operands: a+b+c", function()
  eq(paren._wrap_last_n_operands("a+b+c", 3, PP), "(a+b+c)")
end)

test("wrap more than total operands", function()
  eq(paren._wrap_last_n_operands("a+b+c", 10, PP), "(a+b+c)")
end)

test("single operand wraps whole thing", function()
  eq(paren._wrap_last_n_operands("x", 1, PP), "(x)")
end)

test("empty string stays empty", function()
  eq(paren._wrap_last_n_operands("", 1, PP), "")
end)

test("wrap with square brackets", function()
  eq(paren._wrap_last_n_operands("a+b+c", 1, SQ), "a+b+[c]")
end)

test("wrap with curly brackets", function()
  eq(paren._wrap_last_n_operands("a+b+c", 1, CU), "a+b+{c}")
end)

test("wrap with spaces: a + b + c", function()
  eq(paren._wrap_last_n_operands("a + b + c", 1, PP), "a + b + (c)")
end)

test("wrap 2 with spaces: a + b + c", function()
  eq(paren._wrap_last_n_operands("a + b + c", 2, PP), "a + (b + c)")
end)

test("wrap all with spaces: a + b + c", function()
  eq(paren._wrap_last_n_operands("a + b + c", 3, PP), "(a + b + c)")
end)

test("nested parens: a+(b*c)+d wrap 1", function()
  eq(paren._wrap_last_n_operands("a+(b*c)+d", 1, PP), "a+(b*c)+(d)")
end)

test("nested parens: a+(b*c)+d wrap 2", function()
  eq(paren._wrap_last_n_operands("a+(b*c)+d", 2, PP), "a+((b*c)+d)")
end)

test("unmatched opener: func(a+b+c wrap 1", function()
  eq(paren._wrap_last_n_operands("func(a+b+c", 1, PP), "func(a+b+(c)")
end)

test("unmatched opener: func(a+b+c wrap 2", function()
  eq(paren._wrap_last_n_operands("func(a+b+c", 2, PP), "func(a+(b+c)")
end)

test("unmatched opener: func(a+b+c wrap 3", function()
  eq(paren._wrap_last_n_operands("func(a+b+c", 3, PP), "func((a+b+c)")
end)

test("comma operator: a,b,c wrap 1", function()
  eq(paren._wrap_last_n_operands("a,b,c", 1, PP), "a,b,(c)")
end)

test("string literal preserved", function()
  eq(paren._wrap_last_n_operands('"hello+world"+b', 1, PP), '"hello+world"+(b)')
end)

test("multi-char operator: a**b+c wrap 1", function()
  eq(paren._wrap_last_n_operands("a**b+c", 1, PP), "a**b+(c)")
end)

test("multi-char operator: a**b+c wrap 2", function()
  eq(paren._wrap_last_n_operands("a**b+c", 2, PP), "a**(b+c)")
end)

-- ── preview_line (integration) ────────────────────────────────────────

io.write("\n=== preview_line ===\n")

test("basic .) at end of line", function()
  local preview, col = paren.preview_line("a+b+c.)", 7)
  eq(preview, "a+b+(c)")
  eq(col, 7)
end)

test("basic .)) at end of line", function()
  local preview, col = paren.preview_line("a+b+c.))", 8)
  eq(preview, "a+(b+c)")
  eq(col, 7)
end)

test(".))) wraps all three", function()
  local preview, col = paren.preview_line("a+b+c.)))", 9)
  eq(preview, "(a+b+c)")
  eq(col, 7)
end)

test("cursor in middle: a+b.)+c", function()
  local before_len = #"a+b.)"
  local preview, col = paren.preview_line("a+b.)+c", before_len)
  eq(preview, "a+(b)+c")
  eq(col, #"a+(b)")
end)

test("no trigger returns nil", function()
  local preview, col = paren.preview_line("a+b+c", 5)
  eq(preview, nil)
  eq(col, nil)
end)

test("empty line returns nil", function()
  local preview, col = paren.preview_line("", 0)
  eq(preview, nil)
  eq(col, nil)
end)

test("square brackets: a+b.]", function()
  local preview, col = paren.preview_line("a+b.]", 5)
  eq(preview, "a+[b]")
  eq(col, 5)
end)

test("curly brackets: a+b.}", function()
  local preview, col = paren.preview_line("a+b.}", 5)
  eq(preview, "a+{b}")
  eq(col, 5)
end)

test("with trailing text after cursor", function()
  local preview, col = paren.preview_line("x+y.) + z", 5)
  eq(preview, "x+(y) + z")
  eq(col, #"x+(y)")
end)

test("spaced expression: a + b + c.)", function()
  local preview, col = paren.preview_line("a + b + c.)", 11)
  eq(preview, "a + b + (c)")
  eq(col, 11)
end)

test("spaced expression: a + b + c.))", function()
  local preview, col = paren.preview_line("a + b + c.))", 12)
  eq(preview, "a + (b + c)")
  eq(col, 11)
end)

test("preview same as line returns nil", function()
  -- Single operand with 1 bracket => wraps whole thing, "(x)" != "x.)"
  -- Actually let's construct a case where preview == line:
  -- This shouldn't normally happen, but check that the function handles it
  local preview, col = paren.preview_line("hello", 5)
  eq(preview, nil)
end)

test("unmatched opener in expr: func(a+b.)", function()
  -- The trigger ) consumed the func( closer. Balance repair restores it.
  local preview, col = paren.preview_line("func(a+b.)", 10)
  eq(preview, "func(a+(b))")
  eq(col, 10)
end)

-- ── has_suffix / expand_inline (backward compat) ─────────────────────

io.write("\n=== edge cases ===\n")

test("autopairs: print(1+(b)+c.) single bracket", function()
  local preview, col = paren.preview_line("print(1 + (b) + c.)", 20)
  eq(preview, "print(1 + (b) + (c))")
  eq(col, 19)
end)

test("autopairs: print(1+(b)+c.)) double bracket", function()
  -- .)) wraps 2 operands, restores 1 closer for print(
  local preview, col = paren.preview_line("print(1 + (b) + c.))", 21)
  eq(preview, "print(1 + ((b) + c))")
  -- cursor after wrap's ), before restored )
  eq(col, 19)
end)

test("autopairs: nested (a + (b + c.)) restores 2 closers", function()
  local preview, col = paren.preview_line("(a + (b + c.))", 14)
  eq(preview, "(a + ((b + c)))")
  eq(col, 13)
end)

test("no autopairs: func(a+b.)+c) closer in after", function()
  -- after="+c)" already has the closer for func(, no deficit
  local preview, col = paren.preview_line("func(a+b.)+c)", 10)
  eq(preview, "func(a+(b)+c)")
  eq(col, 10)
end)

test("python false positive: (1+1.) would trigger", function()
  -- Triggers but produces balanced output. User cancels via Space.
  local preview, _ = paren.preview_line("(1+1.)", 6)
  eq(preview, "(1+(1))")
end)

test("multiple dots in expression", function()
  local preview, col = paren.preview_line("a.x+b.y.)", 9)
  -- expr = "a.x+b.y", count=1, dots aren't operators
  -- top-level op: "+" only => wrap last 1 operand = "a.x+(b.y)"
  eq(preview, "a.x+(b.y)")
  eq(col, #"a.x+(b.y)")
end)

-- ── Summary ──────────────────────────────────────────────────────────

io.write(string.format("\n%d passed, %d failed\n", pass_count, fail_count))
if fail_count > 0 then
  os.exit(1)
end
os.exit(0)
