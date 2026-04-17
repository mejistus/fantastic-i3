vim.g.tex_flavor = "latex"
vim.g.vimtex_quickfix_mode = 0
vim.g.vimtex_quickfix_open_on_warning = 0
vim.g.tex_conceal = "abdmg"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_texcount_custom_arg = " -ch -total"

vim.g.vimtex_toc_config = {
  name = "TOC",
  layers = { "content", "todo", "include" },
  split_width = 25,
  todo_sorted = 0,
  show_help = 1,
  show_numbers = 1,
}

vim.g.vimtex_compiler_latexmk = {
  build_dir = "build",
  callback = 1,
  continuous = 1,
  executable = "latexmk",
  hooks = {},
  options = {
    "-pdf",
    "-bibtex",
    "-verbose",
    "-file-line-error",
    "-shell-escape",
    "-synctex=1",
    "-interaction=nonstopmode",
  },
}

vim.g.vimtex_view_general_options =
  '--synctex-forward @line:@col:@pdf --synctex-editor-command "nvim --headless -c \\"VimtexInverseSearch {input} {line}\\""'
vim.g.vimtex_view_method = "skim"
