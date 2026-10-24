# bin/patch-claude-code

Point the official **Claude Code** client at a third-party, Anthropic-compatible
gateway — one command, no binary patching.

Claude Code reads its provider from `~/.claude/settings.json`. Switching gateways
by hand means keeping six or seven keys in sync: `ANTHROPIC_BASE_URL`,
`ANTHROPIC_AUTH_TOKEN`, the three `ANTHROPIC_DEFAULT_*_MODEL` aliases,
`CLAUDE_CODE_MAX_CONTEXT_TOKENS`, plus `model` and the `modelPicker` rows that
`/model` renders. This script packages that into named **provider profiles** and
does the patching, verification and rollback for you.

Python 3 standard library only. Nothing outside `~/.claude/` is touched.

## Install

```sh
git clone https://github.com/mejistus/fantastic-i3 && cd fantastic-i3
./bin/patch-claude-code link          # symlink into ~/.local/bin
```

Then, with Claude Code already installed the official way
(`npm i -g @anthropic-ai/claude-code`, or the native installer):

```sh
patch-claude-code setup --preset minimax-cn
```

That one command picks the gateway, asks for the key if it cannot find one,
writes the profile, activates it, and sends one real request to prove the
endpoint answers. Reopen Claude Code afterwards; `/model` (or `alt+p`) then lists
the models of that gateway.

## Presets

| preset | endpoint | key variable |
| --- | --- | --- |
| `minimax-cn` | `api.minimaxi.com/anthropic` | `$MINIMAX` |
| `opencode-go` | `opencode.ai/inference/go/anthropic` | `$OPENCODE_GO_APIKEY` |
| `opencode-free` | `opencode.ai/inference/anthropic` | `$OPENCODE_GO_APIKEY` |
| `deepseek` | `api.deepseek.com/anthropic` | `$DEEPSEEK_API_KEY` |

`opencode-free` is listed for completeness, not because it works: the free tier is
gated server-side to the OpenCode client itself. Calling it from anywhere else —
Claude Code, curl, a different User-Agent, any free model id — returns
`403 FreeTierError: OpenCode's free tier can only be used from within OpenCode`.
`verify` reports exactly that, and the preset rows are labelled `仅 OpenCode 内可用`
so nobody mistakes them for a working option.

Keys are read in this order: `--key` → the variable in `~/.zshrc` → the same
variable in the environment → an interactive prompt (no echo). When the key comes
from a variable, the profile stores **only the variable name**; the secret never
enters the profile file or this repo.

Any other gateway:

```sh
patch-claude-code add mygateway \
    --base-url https://api.example.com/anthropic \
    --auth-var EXAMPLE_API_KEY \
    --opus big --sonnet mid --haiku small \
    --picker mid --picker big:"Big model":"good for refactors" \
    --discover --verify --activate
```

`--discover` asks the gateway for its model list (`/v1/models`, then `/models`)
and builds the `/model` rows from it.

## Everyday commands

```sh
patch-claude-code list               # profiles, * = active
patch-claude-code use deepseek       # switch (backup written first)
patch-claude-code current            # what is active right now
patch-claude-code verify             # one real /v1/messages round-trip
patch-claude-code models <name> --apply   # refresh picker rows from the gateway
patch-claude-code repair             # re-apply after hand-editing settings.json
patch-claude-code unpatch            # remove the patch, back to official endpoints
patch-claude-code revert             # roll back to the newest backup
```

## Notes

- Every write to `settings.json` is backed up to `~/.claude/backups/`.
- `hooks`, `statusLine`, `enabledPlugins`, `theme` and other unrelated settings
  are preserved verbatim.
- Profiles live in `~/.claude/profiles/` and are **not** part of this repo.
  If you ever pass `--key` instead of `--auth-var`, the profile holds the secret
  and is chmod 600 — keep it out of version control.
- `replaceBuiltInOptions` defaults to on, so `/model` shows exactly the rows you
  configured. Add `--keep-builtin` to append them after the built-in
  Opus/Sonnet/Haiku rows instead.
- A `402 Insufficient account funds` from a gateway is billing, not config.

## 中文速览

`bin/patch-claude-code` 把「让官方 Claude Code 客户端走第三方 Anthropic 兼容网关」
这件事做成一条命令：

```sh
./bin/patch-claude-code link              # 链到 ~/.local/bin
patch-claude-code setup --preset minimax-cn   # 选网关、填 key、激活、探活，一步到位
```

key 优先从 `~/.zshrc` 的变量读，只把变量名写进档案，不落地明文；每次改
`settings.json` 都先备份到 `~/.claude/backups/`，`unpatch` 可整体撤销。
档案在 `~/.claude/profiles/`，不进仓库。
