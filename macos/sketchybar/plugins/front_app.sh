#!/bin/bash
# 当前应用（图标 + 名字）和窗口标题。
# front_app_switched 时 $INFO 是应用名；window_focus / title_change 由 yabairc 触发。
export PATH=/opt/homebrew/bin:/usr/bin:/bin
source "$CONFIG_DIR/icon_map.sh"

win=$(yabai -m query --windows --window 2>/dev/null)
app=$(jq -r '.app // empty' <<<"$win" 2>/dev/null)
title=$(jq -r '.title // empty' <<<"$win" 2>/dev/null)
if [ "$SENDER" = front_app_switched ] && [ -n "$INFO" ] && [ "$INFO" != "$app" ]; then
    # yabai 的焦点窗口有时跟不上（比如切到没有窗口的 Finder）：以前台应用为准，不显示标题
    app=$INFO
    title=
fi
[ -n "$app" ] || app=$(lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null | sed 's/.*="\(.*\)"/\1/')
[ "$title" = "$app" ] && title=

__icon_map "$app"
sketchybar --set front_app icon="$icon_result" label="$app" \
           --set window_title label="$title" drawing="$([ -n "$title" ] && echo on || echo off)"
