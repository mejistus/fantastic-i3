#!/bin/bash
# 苹果菜单（栏最左边的 ）：点  打开 / 收起菜单，点菜单里的一行执行对应的操作。
# 重新启动、关机、退出登录和原生菜单一样，先弹系统的确认框（发给 loginwindow 的 Apple Event）；
# 锁屏用 aero-helper lock（和 ⌃⌘Q 同一个系统函数）；睡眠是 pmset sleepnow，和原生一样立刻睡。
# 菜单打开后和别的面板一样由 aero-helper bar-stats 盯鼠标，离开菜单和  就收起。
STATE="/tmp/yabai-aero-$USER"
HELPER="$HOME/.cache/fantastic-i3/aero-helper"
AERO="$HOME/Documents/fantastic-i3/macos/yabai/aero"
POPUPS="gpu cpu mem disk net input volume battery clock"
[ "$SENDER" = mouse.clicked ] || exit 0

close() {
    sketchybar --set apple popup.drawing=off
    rm -f "$STATE/bar-hover"
}

if [ "$NAME" = apple ]; then
    if [ "$(sketchybar --query apple | jq -r .popup.drawing)" = on ]; then
        close
    else
        # SketchyBar 只在有焦点的那块屏上画面板：点的是别的屏上的 ，先把焦点切过去
        if [ "$(yabai -m query --displays --display mouse 2>/dev/null)" != "$(yabai -m query --displays --display 2>/dev/null)" ]; then
            yabai -m display --focus mouse 2>/dev/null
            sleep 0.3
        fi
        args=()
        for item in $POPUPS; do args+=(--set "$item" popup.drawing=off); done
        mkdir -p "$STATE" && echo apple >"$STATE/bar-hover"
        pkill -USR1 -f "^$HELPER bar-stats"   # 让它开始盯鼠标
        sketchybar "${args[@]}" --set apple popup.drawing=on
    fi
    exit 0
fi

close
"$AERO" log "苹果菜单：${NAME#apple.}"
case "$NAME" in
    apple.about) open "/System/Library/CoreServices/Applications/About This Mac.app" ;;
    apple.settings) open -b com.apple.systempreferences ;;
    apple.appstore) open -b com.apple.AppStore ;;
    apple.sleep) pmset sleepnow ;;
    apple.restart) osascript -e 'tell application "loginwindow" to «event aevtrrst»' ;;
    apple.shutdown) osascript -e 'tell application "loginwindow" to «event aevtrsdn»' ;;
    apple.lock) "$HELPER" lock ;;
    apple.logout) osascript -e 'tell application "loginwindow" to «event aevtlogo»' ;;
esac
