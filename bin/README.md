# bin/patch-claude-code

Point the official **Claude Code** client at a third-party, Anthropic-compatible
gateway — one command, no binary patching.

Claude Code reads its provider from `~/.claude/settings.json`. Switching gateways
by hand means keeping seven or eight keys in sync: `ANTHROPIC_BASE_URL`,
`ANTHROPIC_AUTH_TOKEN`, the three `ANTHROPIC_DEFAULT_*_MODEL` aliases,
`CLAUDE_CODE_MAX_CONTEXT_TOKENS`, plus `model`, the `modelPicker` rows that
`/model` renders, and the optional `fallbackModel` chain. This script packages
that into named **provider profiles** and does the patching, verification and
rollback for you.

Python 3 standard library only. Nothing outside `~/.claude/` is touched.

## Install

```sh
git clone https://github.com/mejistus/fantastic-i3 && cd fantastic-i3
./bin/patch-claude-code link          # symlink into ~/.local/bin
```

Then, with Claude Code already installed the official way
(`npm i -g @anthropic-ai/claude-code`, or the native installer):

```sh
patch-claude-code presets                      # minimax-cn, opencode-go, deepseek
patch-claude-code setup --preset opencode-go   # key read from $OPENCODE_GO_APIKEY
```

That one command picks the gateway, asks for the key if it cannot find one,
writes the profile, activates it, and sends one real request to prove the
endpoint answers. Reopen Claude Code afterwards; `/model` (or `alt+p`) then lists
the models of that gateway.

Same shape for the others:

```sh
patch-claude-code setup --preset minimax-cn    # MiniMax coding plan, $MINIMAX
patch-claude-code setup --preset deepseek      # DeepSeek direct, $DEEPSEEK_API_KEY
patch-claude-code setup --preset deepseek --no-activate   # write the profile, switch later
patch-claude-code setup --preset opencode-go --key-var OPENCODE_GO_APIKEY
```

## Presets

| preset | endpoint | key variable |
| --- | --- | --- |
| `minimax-cn` | `api.minimaxi.com/anthropic` | `$MINIMAX` |
| `opencode-go` | `opencode.ai/inference/go/anthropic` | `$OPENCODE_GO_APIKEY` |
| `deepseek` | `api.deepseek.com/anthropic` | `$DEEPSEEK_API_KEY` |


Keys are read in this order: `--key` → the variable in `~/.zshrc` → the same
variable in the environment → an interactive prompt (no echo). When the key comes
from a variable, the profile stores **only the variable name**; the secret never
enters the profile file or this repo.

`--auth-var` / `--key-var` take the *name*, not the value: `--auth-var OPENCODE_GO_APIKEY`,
**not** `--auth-var $OPENCODE_GO_APIKEY`. The `$` form expands to the secret, and the
script spots it: it warns and treats the value as `--auth-token` instead of storing a
literal key as a variable name. If the variable is unset, the shell drops the argument
entirely and you get a message saying so.

Adding a gateway by hand — OpenCode Go, with real values you can copy:

```sh
patch-claude-code add opencode-go \
    --base-url https://opencode.ai/inference/go/anthropic \
    --auth-var OPENCODE_GO_APIKEY \
    --opus deepseek-v4-pro \
    --sonnet deepseek-v4.1-flash \
    --haiku deepseek-v4.1-flash \
    --picker "deepseek-v4.1-flash:DeepSeek V4.1 Flash:$0.15/$0.6 per Mtok · 1M ctx" \
    --picker "deepseek-v4-pro:DeepSeek V4 Pro:$0.66/$1.98 per Mtok · 1M ctx" \
    --picker kimi-k3 \
    --picker glm-5.3 \
    --no-thinking \
    --max-context 1000000 --verify --activate
```

Any other Anthropic-compatible gateway only changes these four:

| flag | what goes there |
| --- | --- |
| `--base-url` | `https://<your-gateway>/anthropic` |
| `--auth-var` | **name** of the env var holding the key — no `$`: `MINIMAX`, `DEEPSEEK_API_KEY`, `OPENCODE_GO_APIKEY` |
| `--opus/--sonnet/--haiku` | model ids that gateway really serves (`sonnet` is the default, `haiku` backs small internal calls) |
| `--picker ID[:label[:description]]` | the `/model` rows, repeatable, in display order |

`--no-thinking` sets `CLAUDE_CODE_DISABLE_THINKING=1`. DeepSeek's thinking mode
requires every earlier assistant `thinking` block to be sent back; Claude Code
drops unsigned blocks and then gets `400 ... thinking must be passed back`, so the
DeepSeek presets disable thinking by default. `setup --thinking` / `add` without
`--no-thinking` keeps it on if you want to experiment.

`--discover` asks the gateway for its model list (`/v1/models`, then `/models`)
and builds the `/model` rows from it — OpenCode answers 404 there, so it falls
back to the values you passed.

## Everyday commands

```sh
patch-claude-code list               # profiles, * = active
patch-claude-code use opencode-go    # switch (backup written first)
patch-claude-code current            # what is active right now
patch-claude-code verify             # one real /v1/messages round-trip
patch-claude-code models <name> --apply   # refresh picker rows from the gateway
patch-claude-code repair             # re-apply after hand-editing settings.json
patch-claude-code unpatch            # remove the patch, back to official endpoints
patch-claude-code revert             # roll back to the newest backup
patch-claude-code run --profile opencode-go   # start Claude Code behind the retry proxy
```

## One-time setup: plain `claude`

OpenCode Go omits `signature_delta` from thinking blocks. Claude Code then drops
them, and DeepSeek rejects the next turn with `thinking must be passed back`
(surfaced as `400 {"model":"deepseek-v4.1-flash"}` when Go hides the body).
Install the signing + retry proxy once:

```sh
patch-claude-code daemon install --profile opencode-go
```

After that just run `claude` — no wrapper, no `--settings`:

- `ANTHROPIC_BASE_URL` becomes `http://127.0.0.1:8790`
- thinking is enabled; the proxy appends a `signature` before each thinking
  `content_block_stop`, so the block survives the round trip
- `fallbackModel` is removed: it never switches models
- the LaunchAgent `~/Library/LaunchAgents/dev.patch-claude-code.proxy.plist`
  starts it at login and `KeepAlive` restarts it if it dies
- `patch-claude-code daemon status` / `daemon uninstall`; uninstall restores the
  direct URL and turns thinking off, because direct mode cannot sign
- attempts go to `~/.claude/proxy.log` (with `x-opencode-log-id`); daemon errors
  to `~/.claude/proxy-daemon.err.log`

## Temporary: `run`

`run` is the same proxy without installing anything: it lives only as long as one
Claude Code process and overrides the base URL with `--settings`.

```sh
patch-claude-code run --profile opencode-go            # interactive TUI
patch-claude-code run --profile opencode-go -p "hi"    # one-shot, any claude flag works
patch-claude-code run --profile opencode-go -- --resume <id>
```

- Only `400` whose body is exactly `{"model": ...}` (or empty), plus `408/429/5xx`, are retried.
- The first retry keeps the same session id (prompt cache stays warm); later retries
  rotate `x-opencode-session` / `X-Claude-Code-Session-Id` to escape a bad route.
- `run` always clears `fallbackModel` for the session: a request that still fails
  after retries errors out instead of silently switching models.
- `run` re-enables thinking (`CLAUDE_CODE_DISABLE_THINKING=0`) and the proxy signs
  the thinking blocks; `--no-thinking` turns it off for a faster session.
- Attempts are logged to `~/.claude/proxy.log` with the gateway's
  `x-opencode-log-id`, which is what OpenCode support asks for.

Run the proxy alone (for another Anthropic client) with `patch-claude-code proxy`.

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
- DeepSeek in thinking mode requires every earlier assistant `thinking` block to be
  passed back. Claude Code drops blocks without a signature, which surfaces as
  `400 {"model":"deepseek-v4.1-flash"}` on OpenCode Go (the gateway hides the
  message) or as `The content[].thinking ... must be passed back` on DeepSeek direct.
  Without the daemon, the `opencode-go` and `deepseek` presets set
  `CLAUDE_CODE_DISABLE_THINKING=1` so direct `claude` stays usable (no extended
  thinking). `daemon install` or `run` restores thinking and supplies the missing
  signatures.
- No automatic model fallback is configured. Switching a DeepSeek conversation to
  another model leaves assistant turns without DeepSeek thinking, and switching
  back then fails; it also costs more and pollutes the context.
- OpenCode's free tier is gated server-side to the OpenCode client itself: from
  anywhere else it answers `403 FreeTierError`. There is deliberately no preset
  for it — it cannot work as a Claude Code gateway.

## 中文速览

`bin/patch-claude-code` 把「让官方 Claude Code 客户端走第三方 Anthropic 兼容网关」
这件事做成一条命令：

```sh
./bin/patch-claude-code link                  # 链到 ~/.local/bin
patch-claude-code presets                     # 看内置网关
patch-claude-code setup --preset opencode-go  # 选网关、填 key、激活、探活，一步到位
patch-claude-code setup --preset minimax-cn   # MiniMax 编码套餐
```

key 优先从 `~/.zshrc` 的变量读，只把变量名写进档案，不落地明文；每次改
`settings.json` 都先备份到 `~/.claude/backups/`，`unpatch` 可整体撤销。
档案在 `~/.claude/profiles/`，不进仓库。

DeepSeek 的 thinking 模式要求把之前的 assistant `thinking` 块原样回传；
Claude Code 会丢掉没有 signature 的块，于是偶发
`400 {"model":"deepseek-v4.1-flash"}`（Go 网关吞正文）或
`The content[].thinking ... must be passed back`（DeepSeek 官方直连）。

一次性配置（推荐，之后直接 `claude`）：

```sh
patch-claude-code daemon install --profile opencode-go
```

它把 `ANTHROPIC_BASE_URL` 指向本地 `127.0.0.1:8790`，并装一个 launchd 常驻服务：
代理给缺失的 thinking 块补 signature、重试偶发 400、固定清空 `fallbackModel`。
`daemon status` 查看，`daemon uninstall` 恢复直连（直连会重新关 thinking）。

临时用（不装服务）：

```sh
patch-claude-code run --profile opencode-go        # 交互 TUI
patch-claude-code run --profile opencode-go -p "hi"
```

代理只活到这次 Claude Code 退出，不改 `settings.json`；重试记录在
`~/.claude/proxy.log`（含网关的 `x-opencode-log-id`）。
