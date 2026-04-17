local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt
local postfix = require("luasnip.extras.postfix").postfix

require("luasnip.loaders.from_vscode").lazy_load()

ls.add_snippets("python", {
  -- Control flow & utility.
  postfix(".if", {
    f(function(_, parent)
      return ("if %s:"):format(parent.env.POSTFIX_MATCH)
    end, {}),
    i(1, ""),
  }),
  postfix(".ifn", {
    f(function(_, parent)
      return ("if %s is None:"):format(parent.env.POSTFIX_MATCH)
    end, {}),
    i(1, "pass"),
  }),
  postfix(".ifnn", {
    f(function(_, parent)
      return ("if %s is not None:"):format(parent.env.POSTFIX_MATCH)
    end, {}),
    i(1, "pass"),
  }),
  postfix(".not", {
    f(function(_, parent)
      return ("not %s"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".pr", {
    f(function(_, parent)
      return ("print(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".len", {
    f(function(_, parent)
      return ("len(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".str", {
    f(function(_, parent)
      return ("str(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".int", {
    f(function(_, parent)
      return ("int(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".float", {
    f(function(_, parent)
      return ("float(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".list", {
    f(function(_, parent)
      return ("list(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".set", {
    f(function(_, parent)
      return ("set(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".sum", {
    f(function(_, parent)
      return ("sum(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".any", {
    f(function(_, parent)
      return ("any(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  postfix(".all", {
    f(function(_, parent)
      return ("all(%s)"):format(parent.env.POSTFIX_MATCH)
    end, {}),
  }),
  -- Parentheses distance-completion is now provided by cmp source `paren_wrap`.
  s(
    "ifmain",
    fmt(
      [[
if __name__ == "__main__":
    {}
]],
      { i(1, "main()") }
    )
  ),
  s("pp", fmt("print({})", { i(1, "") })),
  s("ret", fmt("return {}", { i(1, "") })),
  s("imp", fmt("import {}", { i(1, "module") })),
  s("fromimp", fmt("from {} import {}", { i(1, "module"), i(2, "name") })),
  s("def", fmt("def {}({}):\n    {}", { i(1, "func"), i(2, "args"), i(3, "pass") })),
  s("cls", fmt("class {}({}):\n    {}", { i(1, "ClassName"), i(2, "object"), i(3, "pass") })),
  s("fori", fmt("for {} in {}:\n    {}", { i(1, "item"), i(2, "iterable"), i(3, "pass") })),
  s("wh", fmt("while {}:\n    {}", { i(1, "cond"), i(2, "pass") })),
  s("try", fmt("try:\n    {}\nexcept {} as {}:\n    {}", { i(1, "pass"), i(2, "Exception"), i(3, "e"), i(4, "pass") })),
  s("with", fmt("with {} as {}:\n    {}", { i(1, "ctx"), i(2, "name"), i(3, "pass") })),
  s("lambda", fmt("lambda {}: {}", { i(1, "x"), i(2, "x") })),
  s("ann", fmt("{}: {}", { i(1, "name"), i(2, "type") })),
  s("doc", { t('"""'), i(1, "description"), t({ '"""', "" }) }),
})
