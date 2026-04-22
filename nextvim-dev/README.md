# Neovim Config (Decoupled From NvChad)

This directory is a standalone Neovim configuration based on `lazy.nvim`.

## What changed

- Removed direct dependency on `NvChad/NvChad`.
- Replaced `nvchad.*` modules with native/lazy equivalents.
- Kept your key workflows: LSP, format, DAP, `oil.nvim`, VimTeX, Treesitter, Telescope.
- Integrated LLM-powered AI coding assistance via SiliconFlow.

## AI Coding Features

Cursor-like AI coding powered by SiliconFlow (OpenAI-compatible API):

| Key | Mode | Action |
|-----|------|--------|
| `<leader>aa` | n/v | AI Actions palette |
| `<leader>ac` | n/v | AI Chat |
| `<leader>ai` | n/v | AI Inline Edit |
| `<leader>at` | n | AI Toggle Chat |
| `<leader>an` | n/v | AI New Chat |
| `<leader>av` | n/v | Avante Ask |
| `<leader>ar` | n | Avante Chat |
| `<leader>ae` | n/v | Avante Edit (diff) |
| `<leader>as` | n | Switch AI Provider |
| `<C-a>` | n/v | Quick AI Prompt |
| `ga` | v | Add selection to chat |

Set `SILICONFLOW_API_KEY` env var or it defaults to the built-in key.

## Structure

- `init.lua`: bootstrap + module loading
- `lua/core`: options/autocmds/keymaps/highlight/runtime
- `lua/plugins`: plugin specs (init.lua, ai.lua)
- `lua/configs`: per-plugin setup
- `tests/`: automated test suite

## Running Tests

```sh
nvim --headless -u NONE -l tests/test_ai_integration.lua
nvim --headless -u NONE -l tests/test_paren_wrap.lua
```
