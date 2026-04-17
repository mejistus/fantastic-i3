local bold_groups = {
  "@keyword",
  "@keyword.operator",
  "@keyword.conditional",
  "@keyword.repeat",
  "@keyword.exception",
  "@keyword.import",
  "@keyword.modifier",
  "@function.builtin",
  "@function.macro",
  "@conditional",
  "@repeat",
  "@exception",
  "@type",
  "@type.builtin",
  "@constructor",
  "@module",
  "@namespace",
  "@constant.builtin",
  "@variable.builtin",
  "@tag",
  "@keyword.return",
  "@keyword.function",
  "Keyword",
  "Conditional",
  "Repeat",
  "Exception",
  "Statement",
  "Type",
  "Function",
  "Include",
  "PreProc",
}

local italic_groups = {
  "@variable.parameter",
  "@comment",
  "@string.documentation",
}

local lang_fallback_bold_groups = {
  "pythonStatement",
  "pythonConditional",
  "pythonRepeat",
  "pythonException",
  "pythonInclude",
  "pythonFunction",
  "pythonBuiltin",
}

local function set_group_style(group, style)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl then
    vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", hl, style))
  else
    vim.api.nvim_set_hl(0, group, style)
  end
end

local function apply()
  for _, group in ipairs(bold_groups) do
    set_group_style(group, { bold = true })
  end
  for _, group in ipairs(italic_groups) do
    set_group_style(group, { italic = true })
  end
  for _, group in ipairs(lang_fallback_bold_groups) do
    set_group_style(group, { bold = true })
  end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  pattern = "*",
  callback = function()
    vim.defer_fn(apply, 50)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.defer_fn(apply, 20)
  end,
})

apply()
