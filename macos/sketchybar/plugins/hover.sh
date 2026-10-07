#!/bin/bash
# 系统项的点击（不再悬停弹面板：时灵时不灵，还容易误触）：
#   点栏上的项：打开它的弹出面板，再点一次收起；鼠标离开这一项和面板后 aero-helper bar-stats 也会收起。
#     打开时把项名写进 bar-hover、给 bar-stats 发 SIGUSR1，让它马上推这一项的详情（之后每 2 秒更新）、开始盯鼠标。
#     SketchyBar 只在有焦点的那块屏上画面板（"显示器具有单独的空间"打开时）：点的是别的屏上的项，先把焦点切过去。
#   点面板的标题行（<项>.title，最右边有个 ↗，鼠标移上去变亮）：打开对应的应用或设置页
#     （记一行到 aero.log，点了没反应时可以查）。
#   音量面板里点"静音"那一行：静音 / 取消静音。
# 有自己脚本的项（音量、电池、日期）在它们的脚本里把点击转给这里。网速拆成了 net / net.rx / net.tx 三块，都按 net 处理。
STATE="/tmp/yabai-aero-$USER"
HELPER="$HOME/.cache/fantastic-i3/aero-helper"
AERO="$HOME/Documents/fantastic-i3/macos/yabai/aero"
POPUPS="gpu cpu mem disk net input volume battery clock apple"
ITEM=${NAME%%.*}

case "$SENDER" in   # 标题行的 ↗：鼠标移上去变亮
    mouse.entered) sketchybar --set "$NAME" background.image="$CONFIG_DIR/icons/open-hover.png"; exit 0 ;;
    mouse.exited) sketchybar --set "$NAME" background.image="$CONFIG_DIR/icons/open.png"; exit 0 ;;
    mouse.clicked) ;;
    *) exit 0 ;;
esac

close() {
    sketchybar --set "$ITEM" popup.drawing=off
    rm -f "$STATE/bar-hover"
}

case "$NAME" in
    "$ITEM" | net.rx | net.tx)   # 栏上的项：打开 / 收起面板
        if [ "$(sketchybar --query "$ITEM" | jq -r .popup.drawing)" = on ]; then
            close
            exit 0
        fi
        if [ "$(yabai -m query --displays --display mouse 2>/dev/null)" != "$(yabai -m query --displays --display 2>/dev/null)" ]; then
            yabai -m display --focus mouse 2>/dev/null
            sleep 0.3   # 等 SketchyBar 知道焦点换了屏
        fi
        args=()
        for item in $POPUPS; do
            [ "$item" = "$ITEM" ] || args+=(--set "$item" popup.drawing=off)
        done
        mkdir -p "$STATE" && echo "$ITEM" >"$STATE/bar-hover"
        pkill -USR1 -f "^$HELPER bar-stats"
        sketchybar "${args[@]}" --set "$ITEM" popup.drawing=on
        ;;
    volume.muted)
        osascript -e 'set volume output muted (not (output muted of (get volume settings)))'
        pkill -USR1 -f "^$HELPER bar-stats"   # 马上刷新面板
        ;;
    *.title)
        sketchybar --set "$NAME" background.image="$CONFIG_DIR/icons/open.png"
        close
        "$AERO" log "顶栏打开：$ITEM"
        case "$ITEM" in
            gpu | cpu | mem) open -b com.apple.ActivityMonitor ;;
            disk) open "x-apple.systempreferences:com.apple.settings.Storage" ;;
            net) open "x-apple.systempreferences:com.apple.Network-Settings.extension" ;;
            input) open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" ;;
            volume) open "x-apple.systempreferences:com.apple.Sound-Settings.extension" ;;
            battery) open "x-apple.systempreferences:com.apple.Battery-Settings.extension" ;;
            clock) open -b com.apple.iCal ;;
        esac
        ;;
esac
