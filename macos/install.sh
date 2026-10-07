#!/bin/bash
# macOS 平铺窗口管理（yabai + skhd）一键安装。可以重复运行：已经做好的步骤会跳过。
# 跑法：bash <仓库>/macos/install.sh
#
# 做的事：
#   1. 检查 Apple Silicon、Xcode 命令行工具（swiftc 编译 aero-helper，otool 给 setup-sa 用）、Homebrew
#   2. 用 brew 安装 yabai、skhd、jq、SketchyBar，以及字体 Maple Mono NF、sketchybar-app-font
#   3. 仓库要在 ~/Documents/fantastic-i3（skhdrc 里写的是这个路径）：克隆在别处就在那里建一个链接
#   4. 链接配置：~/.config/yabai/yabairc、~/.config/skhd/skhdrc、~/.config/sketchybar（原来的会备份）
#   5. 关掉调度中心的"根据最近的使用情况自动重新排列空间"（否则桌面顺序会变，工作区编号就乱了）；
#      菜单栏设为自动隐藏（顶上换成 SketchyBar）
#   6. 编译 aero-helper（窗口切换列表等）
#   7. 启动 yabai、skhd、SketchyBar 服务，检查辅助功能权限
#   8. 检查桌面够不够 10 个
#
# 要自己动手的：给 yabai、skhd 辅助功能权限（脚本会打开设置页面）；在调度中心里把桌面加到 10 个。
# 想要瞬间切换桌面（没有动画）：再运行 yabai/setup-sa（要先在恢复模式里部分关闭 SIP，见它开头的说明）。
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
HOME_REPO="$HOME/Documents/fantastic-i3"
AERO="$HOME_REPO/macos/yabai/aero"
todo=()

ok() { echo "✓ $*"; }
die() { echo "✗ $*" >&2; exit 1; }

# ---- 1. 前提 ----
[ "$(uname -s)" = Darwin ] || die "只支持 macOS"
[ "$(uname -m)" = arm64 ] || die "只支持 Apple Silicon（脚本里的路径都是 /opt/homebrew）"
if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install >/dev/null 2>&1 || true
    die "需要 Xcode 命令行工具：在弹出的窗口里安装，装好后再运行一次本脚本"
fi
[ -x /opt/homebrew/bin/brew ] || die "需要 Homebrew：先按 https://brew.sh 安装，再运行一次本脚本"
eval "$(/opt/homebrew/bin/brew shellenv)"
ok "Apple Silicon、Xcode 命令行工具、Homebrew"

# ---- 2. 软件 ----
for f in asmvik/formulae/yabai asmvik/formulae/skhd FelixKratz/formulae/sketchybar jq; do
    brew list --formula "${f##*/}" >/dev/null 2>&1 || brew install "$f"
done
for f in font-maple-mono-nf font-sketchybar-app-font; do   # sketchybar-app-font 要和 sketchybar/icon_map.sh 同一版本
    brew list --cask "$f" >/dev/null 2>&1 || brew install --cask "$f"
done
ok "yabai $(yabai --version | sed 's/yabai-v//')、skhd、$(sketchybar --version | sed 's/-v/ /')、jq、字体"

# ---- 3. 仓库位置 ----
if [ "$(cd "$HOME_REPO" 2>/dev/null && pwd -P)" != "$REPO" ]; then
    if [ -e "$HOME_REPO" ] || [ -L "$HOME_REPO" ]; then
        die "$HOME_REPO 已经存在，但不是这个仓库（$REPO）：移走它，或者把仓库放到那里"
    fi
    mkdir -p "$(dirname "$HOME_REPO")"
    ln -s "$REPO" "$HOME_REPO"
fi
ok "仓库：$HOME_REPO$([ -L "$HOME_REPO" ] && echo " → $REPO")"

# ---- 4. 配置文件 ----
link() { # <仓库里的文件> <链接位置>
    local src=$1 dst=$2
    if [ "$(readlink "$dst" 2>/dev/null)" != "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mv "$dst" "$dst.bak-$(date +%Y%m%d-%H%M%S)"
            echo "  原来的 $dst 已备份"
        fi
        ln -s "$src" "$dst"
    fi
    ok "$dst → $src"
}
link "$HOME_REPO/macos/yabai/yabairc" "$HOME/.config/yabai/yabairc"
link "$HOME_REPO/macos/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"
link "$HOME_REPO/macos/sketchybar" "$HOME/.config/sketchybar"
# skhdrc 末尾 .load 这个文件；之后由 aero keys 按 SA 是否加载切换成 sa / native，这里只在没有时先放一个
[ -e "$HOME/.config/skhd/workspaces.skhdrc" ] ||
    ln -sfn "$HOME_REPO/macos/skhd/workspaces-native.skhdrc" "$HOME/.config/skhd/workspaces.skhdrc"

# ---- 5. 调度中心 ----
if [ "$(defaults read com.apple.dock mru-spaces 2>/dev/null)" != 0 ]; then
    defaults write com.apple.dock mru-spaces -bool false
    killall Dock
fi
ok "调度中心：不按最近使用情况重新排列空间"
if [ "$(osascript -e 'tell application "System Events" to get autohide menu bar of dock preferences' 2>/dev/null)" != true ]; then
    osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to true' >/dev/null 2>&1 ||
        todo+=("系统设置 → 控制中心 → 自动隐藏和显示菜单栏：选\"始终\"（顶上换成了 SketchyBar）")
fi
ok "菜单栏：自动隐藏"
if [ "$(defaults read com.apple.spaces spans-displays 2>/dev/null)" = 1 ]; then
    todo+=("系统设置 → 桌面与程序坞 → 打开\"显示器具有单独的空间\"，然后注销重新登录（yabai 需要）")
fi

# ---- 6. aero-helper ----
"$AERO" helper >/dev/null 2>&1 || true    # 不带参数：需要时编译，然后只打印用法
[ -x "$HOME/.cache/fantastic-i3/aero-helper" ] ||
    die "aero-helper 编译失败：swiftc -O -o ~/.cache/fantastic-i3/aero-helper $HOME_REPO/macos/yabai/helper/main.swift"
ok "aero-helper"

# ---- 7. 服务和权限 ----
for app in AeroSpace AltTab; do
    if pgrep -xq "$app"; then todo+=("退出 $app 并关掉它的开机启动（会和 yabai / ⌥⇥ 冲突）"); fi
done
pgrep -xq yabai || yabai --start-service
pgrep -xq skhd || skhd --start-service
pgrep -xq sketchybar || brew services start sketchybar >/dev/null

yabai_ok=0
for _ in $(seq 20); do
    yabai -m query --spaces >/dev/null 2>&1 && { yabai_ok=1; break; }
    sleep 0.5
done
skhd_pid=$(pgrep -x skhd || true)
sleep 2
skhd_ok=0
[ -n "$skhd_pid" ] && [ "$(pgrep -x skhd || true)" = "$skhd_pid" ] && skhd_ok=1   # 没有权限时 skhd 会退出、被 launchd 重启
if [ "$yabai_ok$skhd_ok" = 11 ]; then
    ok "yabai、skhd 在运行，有辅助功能权限"
    "$AERO" reload   # yabai 先于 SketchyBar 启动时，yabairc 里给顶栏留空间的设置还没生效
else
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    todo+=("系统设置 → 隐私与安全性 → 辅助功能：打开 yabai 和 skhd（没有就点 + 从 /opt/homebrew/bin 添加），然后再运行一次本脚本")
fi

# ---- 8. 桌面 ----
if [ "$yabai_ok" = 1 ]; then
    have=$(yabai -m query --spaces | jq '[.[] | select(."is-native-fullscreen" | not)] | length')
    if [ "$have" -ge 10 ]; then
        ok "桌面：$have 个"
    else
        todo+=("调度中心里把桌面加到 10 个（现在 $have 个）；或者运行 $HOME_REPO/macos/yabai/setup-sa，加载 SA 后会自动补齐")
    fi
    echo
    "$AERO" status
fi

echo
if [ ${#todo[@]} -eq 0 ]; then
    echo "全部完成。⌥1…⌥0 切换工作区，⌥⇧+数字 移动窗口，⌥⇥ 切换窗口。"
else
    echo "还需要手动做："
    printf '  - %s\n' "${todo[@]}"
fi
echo "可选：瞬间切换桌面（没有动画）需要 yabai 脚本扩展，见 $HOME_REPO/macos/yabai/setup-sa"
