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
    --fallback minimax-m3,qwen3.8-flash \
    --max-context 1000000 --verify --activate
```

Any other Anthropic-compatible gateway only changes these four:

| flag | what goes there |
| --- | --- |
| `--base-url` | `https://<your-gateway>/anthropic` |
| `--auth-var` | **name** of the env var holding the key — no `$`: `MINIMAX`, `DEEPSEEK_API_KEY`, `OPENCODE_GO_APIKEY` |
| `--opus/--sonnet/--haiku` | model ids that gateway really serves (`sonnet` is the default, `haiku` backs small internal calls) |
| `--picker ID[:label[:description]]` | the `/model` rows, repeatable, in display order |

`--fallback a,b` (or repeated, up to three) writes Claude Code's `fallbackModel`
chain: when the primary returns a non-retryable error such as an upstream 400,
Claude Code retries the same turn on the next model and returns to the primary
at the start of the next user turn.

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

## Retry proxy (OpenCode Go's opaque 400s)

OpenCode Go sometimes answers

```
400 {"model":"deepseek-v4.1-flash"}
```

with no error text — it drops the upstream body (`opencode#53243`, `#54996`). The
same request usually succeeds on a retry, so `run` starts a local proxy for the
lifetime of one Claude Code process and transparently retries:

```sh
patch-claude-code run --profile opencode-go            # interactive TUI
patch-claude-code run --profile opencode-go -p "hi"    # one-shot, any claude flag works
patch-claude-code run --profile opencode-go -- --resume <id>
```

- Only `400` whose body is exactly `{"model": ...}` (or empty), plus `408/429/5xx`, are retried.
- The first retry keeps the same session id (prompt cache stays warm); later retries
  rotate `x-opencode-session` / `X-Claude-Code-Session-Id` to escape a bad route.
- `ANTHROPIC_BASE_URL` is overridden per-process with `--settings` — `settings.json`
  is not modified, no daemon, and the proxy dies with Claude Code.
- `--no-fallback` clears `fallbackModel` for the session, so a request that still
  fails after retries errors out instead of silently switching models.
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
- OpenCode Go's Anthropic endpoint occasionally answers `400 {"model":"deepseek-v4.1-flash"}`
  — the gateway drops the upstream error body, so the real cause is invisible. The
  request often succeeds when retried. The `opencode-go` preset ships
  `fallbackModel: ["minimax-m3", "qwen3.8-flash"]`, so Claude Code switches models
  for that turn instead of failing. Use `patch-claude-code use deepseek` to avoid
  that gateway entirely if it becomes frequent.
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

OpenCode Go 的 `deepseek-v4.1-flash` 会偶发 `400 {"model":"deepseek-v4.1-flash"}`
（网关吞掉上游错误正文，重试通常能过）。`opencode-go` 预设已配
`fallbackModel: minimax-m3, qwen3.8-flash`，Claude Code 会在那一回合自动换模型；
嫌频繁就 `patch-claude-code use deepseek` 直接走 DeepSeek 官方端点。

更推荐用带重试代理的方式启动，既保留 DeepSeek 又不用切模型：

```sh
patch-claude-code run --profile opencode-go        # 交互 TUI
patch-claude-code run --profile opencode-go -p "hi"
```

代理只活到这次 Claude Code 退出，不改 `settings.json`；重试记录在
`~/.claude/proxy.log`（含网关的 `x-opencode-log-id`）。
