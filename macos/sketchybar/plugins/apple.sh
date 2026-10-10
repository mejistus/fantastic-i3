#!/bin/bash
# 苹果菜单（栏最左边的 ）：点  弹出菜单。菜单是 aero-helper apple-menu 弹的系统菜单（和原生的一样有毛玻璃、悬停高亮、
# 键盘操作，深浅色跟着系统），它把选中的那一行打印出来，这里执行。菜单开着时  有一块和原生一样的高亮底色。
# 重新启动、关机、退出登录和原生菜单一样，先弹系统的确认框（发给 loginwindow 的 Apple Event）；
# 锁屏用 aero-helper lock（和 ⌃⌘Q 同一个系统函数）；睡眠是 pmset sleepnow，和原生一样立刻睡。
STATE="/tmp/yabai-aero-$USER"
HELPER="$HOME/.cache/fantastic-i3/aero-helper"
AERO="$HOME/Documents/fantastic-i3/macos/yabai/aero"
POPUPS="gpu cpu mem disk net input volume battery clock"
[ "$SENDER" = mouse.clicked ] || exit 0

# 菜单开着时再点 ：那一下先把菜单关掉了，这里就不再打开（和原生的一样，点一下开、再点一下关）
pgrep -qf "^$HELPER apple-menu" && exit 0

args=()
for item in $POPUPS; do args+=(--set "$item" popup.drawing=off); done
rm -f "$STATE/bar-hover"
sketchybar "${args[@]}" --set apple background.drawing=on
choice=$("$HELPER" apple-menu "$(sketchybar --query apple | jq -c '[.bounding_rects[] | select(.origin[0] > -9000)]')")
sketchybar --set apple background.drawing=off
[ -n "$choice" ] || exit 0

"$AERO" log "苹果菜单：$choice"
case "$choice" in
    about) open "/System/Library/CoreServices/Applications/About This Mac.app" ;;
    settings) open -b com.apple.systempreferences ;;
    appstore) open -b com.apple.AppStore ;;
    sleep) pmset sleepnow ;;
    restart) osascript -e 'tell application "loginwindow" to «event aevtrrst»' ;;
    shutdown) osascript -e 'tell application "loginwindow" to «event aevtrsdn»' ;;
    lock) "$HELPER" lock ;;
    logout) osascript -e 'tell application "loginwindow" to «event aevtlogo»' ;;
esac
