#!/bin/bash
# macOS 平铺窗口管理（yabai + skhd + SketchyBar）一键安装。可以重复运行：已经做好的步骤会跳过。
# 跑法：
#   新电脑上一行就够（会装 Homebrew，再把仓库克隆到 ~/Documents/fantastic-i3-macOS）：
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mejistus/fantastic-i3-macOS/main/install.sh)"
#   已经克隆了：bash <仓库>/install.sh（fantastic-i3 里它是子模块 macos/，就是 bash <fantastic-i3>/macos/install.sh）
#   只看快捷键表：bash <仓库>/install.sh --keys
#
# 做的事：
#   1. 检查 Apple Silicon；没有 Homebrew 就用官方脚本装（会问开机密码，顺带装 Xcode 命令行工具：
#      swiftc 编译 aero-helper，otool 给 setup-sa 用，git 克隆仓库）
#   2. 仓库要在 ~/Documents/fantastic-i3-macOS（skhdrc 里写的是这个路径）：用 curl 跑的就克隆到那里，
#      克隆在别处（比如 fantastic-i3 的子模块 macos/）就在那里建一个链接
#   3. 逐个检查 yabai、skhd、SketchyBar、jq 和字体 Maple Mono NF、sketchybar-app-font，没装的用 brew 装
#   4. 链接配置：~/.config/yabai/yabairc、~/.config/skhd/skhdrc、~/.config/sketchybar（原来的会备份）
#   5. 关掉调度中心的"根据最近的使用情况自动重新排列空间"（否则桌面顺序会变，工作区编号就乱了）
#   6. 编译 aero-helper（窗口切换列表、顶栏的数据和底板、锁屏等，helper/*.swift）；菜单栏设为自动隐藏（顶上换成 SketchyBar）
#   7. 启动 yabai、skhd、SketchyBar 服务（SketchyBar 已经在跑就重新加载，用上链接好的配置），检查辅助功能权限
#   8. 检查桌面够不够 17 个
#   9. 列出快捷键（第一次用建议截图保存）
#
# 要自己动手的：给 yabai、skhd 辅助功能权限（脚本会打开设置页面）；在调度中心里把桌面加到 17 个。
# 想要瞬间切换桌面（没有动画）：再运行 yabai/setup-sa（要先在恢复模式里部分关闭 SIP，见它开头的说明）。
set -euo pipefail

HOME_REPO="$HOME/Documents/fantastic-i3-macOS"
REPO_URL="https://github.com/mejistus/fantastic-i3-macOS"
AERO="$HOME_REPO/yabai/aero"
todo=()

ok() { echo "✓ $*"; }
die() { echo "✗ $*" >&2; exit 1; }
title() { if [ -t 1 ]; then printf '\033[1m%s\033[0m\n' "$*"; else echo "$*"; fi; }

# 快捷键表（键那一列只用单宽字符，汉字放在行尾，终端里才对得齐）
keys() {
    echo
    title "════════ 快捷键 ════════  第一次用建议截图保存：⌘⇧4，按空格，再点这个窗口"
    title "工作区（顶栏左边是工作区和上面的应用，点一下也能切）"
    cat <<'EOF'
  ⌥1 … ⌥9 ⌥0              切到工作区 1 … 10（⌥ + Caps Lock 也是 10）
  ⌥Z ⌥X ⌥C ⌥B ⌥N ⌥M ⌥T    切到工作区 Z X C B N M T（⌥T 要脚本扩展）
  ⌥⇧1 … ⌥⇧0, ⌥⇧Z … ⌥⇧T    把当前窗口移到那个工作区，人也跟过去
  ⌃H / ⌃L                 上一个 / 下一个工作区
EOF
    title "窗口"
    cat <<'EOF'
  ⌥H/J/K/L, ⌥←↓↑→        焦点移到左 / 下 / 上 / 右边的窗口
  ⌥⇧H/J/K/L, ⌥⇧←↓↑→      和那边的窗口交换位置
  ⌥F                      全屏 / 还原
  ⌥⇧F                     平铺 ↔ 浮动
  ⌥- / ⌥=                 缩小 / 放大
  ⌥R                      调大小模式：H J K L 或方向键调宽高，Esc 退出
EOF
    title "切换和打开"
    cat <<'EOF'
  ⌥⇥                      窗口列表：回车回到上一个窗口；直接打字搜索，中文用拼音
  ⌘⇥                      点一下回到上一个应用，按住 ⌘ 列出所有应用
  ⌘Space                  应用列表（代替 Spotlight），打字搜索，回车打开
  ⌥D                      在当前工作区开一个 Finder 窗口
  ⌥G                      工作区 1 的浏览器
EOF
    title "⌃S 服务模式：先按 ⌃S，松开再按下面的键"
    cat <<'EOF'
  ⌃S M                    记住当前应用平铺还是浮动，以后新开的窗口照办
  ⌃S W                    记住当前应用在哪个工作区，以后新开的窗口去那里
  ⌃S F                    当前工作区的窗口全部平铺 ↔ 全部浮动
  ⌃S Esc                  重新加载配置
EOF
    title "其它"
    cat <<'EOF'
  ⌥⇧↩                     临时关掉顶栏，换回系统菜单栏；再按一次换回来
  ⌥⇧⇥                     把当前工作区挪到下一个显示器（要脚本扩展）
EOF
    echo "鼠标移到屏幕最上面会出现系统菜单栏。脚本扩展见 yabai/setup-sa（没有它切工作区有滑动动画）"
    echo "再看这张表：bash $HOME_REPO/install.sh --keys"
}

if [ "${1:-}" = --keys ]; then keys; exit 0; fi

# ---- 1. 前提 ----
[ "$(uname -s)" = Darwin ] || die "只支持 macOS"
[ "$(uname -m)" = arm64 ] || die "只支持 Apple Silicon（脚本里的路径都是 /opt/homebrew）"
if [ ! -x /opt/homebrew/bin/brew ]; then
    echo "→ 安装 Homebrew（官方脚本，会问开机密码，顺带装 Xcode 命令行工具，要等几分钟）"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x /opt/homebrew/bin/brew ] || die "Homebrew 没装上，见上面的输出；也可以按 https://brew.sh 手动装好，再运行一次本脚本"
fi
if ! command -v brew >/dev/null 2>&1 && ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
    # 新开的终端里也能用 brew（Homebrew 装完让你自己加的就是这一行）
    printf '\neval "$(/opt/homebrew/bin/brew shellenv)"\n' >>"$HOME/.zprofile"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install >/dev/null 2>&1 || true
    die "需要 Xcode 命令行工具：在弹出的窗口里安装，装好后再运行一次本脚本"
fi
ok "Apple Silicon、Homebrew、Xcode 命令行工具"

# ---- 2. 仓库位置 ----
self=${BASH_SOURCE[0]:-}
if [ -n "$self" ] && [ -x "$(dirname "$self")/yabai/aero" ]; then
    REPO=$(cd "$(dirname "$self")" && pwd -P)
else
    # 用 curl 跑的：手里只有这个脚本，克隆仓库，再用仓库里的这个脚本接着装
    if [ ! -x "$AERO" ]; then
        if [ -e "$HOME_REPO" ] || [ -L "$HOME_REPO" ]; then
            die "$HOME_REPO 已经存在，但不是这个仓库：移走它，再运行一次"
        fi
        echo "→ 克隆 $REPO_URL 到 $HOME_REPO"
        mkdir -p "$(dirname "$HOME_REPO")"
        git clone "$REPO_URL" "$HOME_REPO"
    fi
    exec /bin/bash "$HOME_REPO/install.sh" "$@"
fi
if [ "$(cd "$HOME_REPO" 2>/dev/null && pwd -P)" != "$REPO" ]; then
    if [ -e "$HOME_REPO" ] || [ -L "$HOME_REPO" ]; then
        die "$HOME_REPO 已经存在，但不是这个仓库（$REPO）：移走它，或者把仓库放到那里"
    fi
    mkdir -p "$(dirname "$HOME_REPO")"
    ln -s "$REPO" "$HOME_REPO"
fi
ok "仓库：$HOME_REPO$([ -L "$HOME_REPO" ] && echo " → $REPO")"

# ---- 3. 软件 ----
need() { # <formula|cask> <brew 里的名字>
    local name=${2##*/}
    if ! brew list "--$1" "$name" >/dev/null 2>&1; then
        echo "→ 安装 $name"
        brew install "--$1" "$2"
    fi
    ok "$(brew list "--$1" --versions "$name")"
}
need formula asmvik/formulae/yabai
need formula asmvik/formulae/skhd
need formula FelixKratz/formulae/sketchybar
need formula jq
need cask font-maple-mono-nf
need cask font-sketchybar-app-font   # 要和 sketchybar/icon_map.sh 同一版本

# ---- 4. 配置文件 ----
link() { # <仓库里的文件> <链接位置>
    local src=$1 dst=$2
    if [ "$(readlink "$dst" 2>/dev/null)" != "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
            rm "$dst"   # 指向同一个文件，只是路径写法不同（比如换成了 ~/Documents/fantastic-i3-macOS）
        elif [ -e "$dst" ] || [ -L "$dst" ]; then
            mv "$dst" "$dst.bak-$(date +%Y%m%d-%H%M%S)"
            echo "  原来的 $dst 已备份"
        fi
        ln -s "$src" "$dst"
    fi
    ok "$dst → $src"
}
link "$HOME_REPO/yabai/yabairc" "$HOME/.config/yabai/yabairc"
link "$HOME_REPO/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"
link "$HOME_REPO/sketchybar" "$HOME/.config/sketchybar"
# skhdrc 末尾 .load 这个文件；之后由 aero keys 按 SA 是否加载切换成 sa / native，这里只在没有时先放一个
[ -e "$HOME/.config/skhd/workspaces.skhdrc" ] ||
    ln -sfn "$HOME_REPO/skhd/workspaces-native.skhdrc" "$HOME/.config/skhd/workspaces.skhdrc"

# ---- 5. 调度中心 ----
if [ "$(defaults read com.apple.dock mru-spaces 2>/dev/null)" != 0 ]; then
    defaults write com.apple.dock mru-spaces -bool false
    killall Dock
fi
ok "调度中心：不按最近使用情况重新排列空间"
if [ "$(defaults read com.apple.spaces spans-displays 2>/dev/null)" = 1 ]; then
    todo+=("系统设置 → 桌面与程序坞 → 打开\"显示器具有单独的空间\"，然后注销重新登录（yabai 需要）")
fi

# ---- 6. aero-helper ----
"$AERO" helper >/dev/null 2>&1 || true    # 不带参数：需要时编译，然后只打印用法
[ -x "$HOME/.cache/fantastic-i3/aero-helper" ] ||
    die "aero-helper 编译失败：swiftc -O -o ~/.cache/fantastic-i3/aero-helper $HOME_REPO/yabai/helper/*.swift"
ok "aero-helper"
# SketchyBar 每次加载也会做；这里先做，yabai 启动时就按自动隐藏排窗口
if "$AERO" helper menubar-autohide on; then
    ok "菜单栏：自动隐藏（顶上换成 SketchyBar）"
else
    todo+=("系统设置 → 控制中心 → 自动隐藏和显示菜单栏：选\"始终\"（顶上换成了 SketchyBar）")
fi

# ---- 7. 服务和权限 ----
for app in AeroSpace AltTab; do
    if pgrep -xq "$app"; then todo+=("退出 $app 并关掉它的开机启动（会和 yabai / ⌥⇥ 冲突）"); fi
done
pgrep -xq yabai || yabai --start-service
pgrep -xq skhd || skhd --start-service
if pgrep -xq sketchybar; then
    sketchybar --reload "$HOME/.config/sketchybar/sketchybarrc"   # 之前装过、还在用旧配置：换成刚链接的
else
    brew services start sketchybar >/dev/null
fi

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
    if [ "$have" -ge 17 ]; then
        ok "桌面：$have 个"
    else
        todo+=("调度中心里把桌面加到 17 个（现在 $have 个）；或者运行 $HOME_REPO/yabai/setup-sa，加载 SA 后会自动补齐")
    fi
fi

# ---- 9. 快捷键 ----
if [ ${#todo[@]} -gt 0 ]; then
    echo
    title "还需要手动做："
    printf '  - %s\n' "${todo[@]}"
else
    echo
    ok "全部完成。出问题时运行 $AERO status 看看"
fi
keys
[ ${#todo[@]} -eq 0 ] || echo "↑ 别忘了快捷键表上面那 ${#todo[@]} 件要手动做的事"
