#!/bin/bash
# 电池：图标随电量变，接着电源时换成充电图标；低于 20% 变红、40% 变黄（黑白主题也是）。没有电池（台式机）就不显示。
# 鼠标悬停、点击：交给 hover.sh
case "$SENDER" in
    mouse.entered | mouse.exited.global | mouse.clicked) exec "$CONFIG_DIR/plugins/hover.sh" ;;
esac
source "$CONFIG_DIR/colors.sh"

info=$(pmset -g batt)
percent=$(grep -Eo '[0-9]+%' <<<"$info" | head -1 | tr -d %)
if [ -z "$percent" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

level=$(( (percent + 5) / 10 ))   # 0-10
if grep -q "AC Power" <<<"$info"; then
    icons=(󰢜 󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)
    color=$BAR_GREEN
else
    icons=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
    if [ "$percent" -lt 20 ]; then color=$ALERT
    elif [ "$percent" -lt 40 ]; then color=$WARN
    else color=$BAR_GREEN
    fi
fi
sketchybar --set "$NAME" drawing=on icon="${icons[level]}" icon.color="$color" label="${percent}%"
