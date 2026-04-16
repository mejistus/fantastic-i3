local bold_groups = {
  "@keyword",
  "@keyword.operator",
  "@conditional",
  "@repeat",
  "@exception",
  "@type.builtin",
  "@constructor",
  "@constant.builtin",
  "@variable.builtin",
  "@tag",
  "@keyword.return",
  "@keyword.function",
}

local italic_groups = {
  "@variable.parameter",
  "@comment",
  "@string.documentation",
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
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.defer_fn(apply, 50)
  end,
})

apply()
