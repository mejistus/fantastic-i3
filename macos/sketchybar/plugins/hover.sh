#!/bin/bash
# 系统项的鼠标事件：
#   悬停：收起别的项的弹出面板，打开这一项的；把项名写进 bar-hover，给 aero-helper bar-stats 发 SIGUSR1，
#         让它马上推这一项的详情（之后每 2 秒更新），鼠标离开这一项和面板后也由它收起面板。
#   点击：打开对应的应用或设置页（记一行到 aero.log，点了没反应时可以查）。
# 有自己脚本的项（音量、电池、日期）在它们的脚本里把这些事件转给这里（音量的点击是静音，自己处理）。
# 网速拆成了 net / net.rx / net.tx 三块（箭头单独上色），都按 net 处理。
STATE="/tmp/yabai-aero-$USER"
HELPER="$HOME/.cache/fantastic-i3/aero-helper"
AERO="$HOME/Documents/fantastic-i3/macos/yabai/aero"
POPUPS="gpu cpu mem disk net input volume battery clock"
ITEM=${NAME%%.*}

case "$SENDER" in
    mouse.entered)
        args=()
        for item in $POPUPS; do
            [ "$item" = "$ITEM" ] || args+=(--set "$item" popup.drawing=off)
        done
        mkdir -p "$STATE" && echo "$ITEM" >"$STATE/bar-hover"
        pkill -USR1 -f "^$HELPER bar-stats"
        sketchybar "${args[@]}" --set "$ITEM" popup.drawing=on
        ;;
    mouse.exited.global)
        sketchybar --set "$ITEM" popup.drawing=off
        [ "$(cat "$STATE/bar-hover" 2>/dev/null)" = "$ITEM" ] && rm -f "$STATE/bar-hover"
        ;;
    mouse.clicked)
        sketchybar --set "$ITEM" popup.drawing=off
        rm -f "$STATE/bar-hover"
        "$AERO" log "顶栏点击：$NAME"
        case "$ITEM" in
            gpu | cpu | mem) open -b com.apple.ActivityMonitor ;;
            disk) open "x-apple.systempreferences:com.apple.settings.Storage" ;;
            net) open "x-apple.systempreferences:com.apple.Network-Settings.extension" ;;
            input) open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" ;;
            battery) open "x-apple.systempreferences:com.apple.Battery-Settings.extension" ;;
            clock) open -b com.apple.iCal ;;
        esac
        ;;
esac
