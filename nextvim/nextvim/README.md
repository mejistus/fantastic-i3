# Neovim Config (Decoupled From NvChad)

This directory is a standalone Neovim configuration based on `lazy.nvim`.

## What changed

- Removed direct dependency on `NvChad/NvChad`.
- Replaced `nvchad.*` modules with native/lazy equivalents.
- Kept your key workflows: LSP, format, DAP, `oil.nvim`, VimTeX, Treesitter, Telescope.

## Structure

- `init.lua`: bootstrap + module loading
- `lua/core`: options/autocmds/keymaps/highlight
- `lua/plugins`: plugin spec
- `lua/configs`: per-plugin setup
