#!/bin/bash
# 音量：滚轮每格调 5；单击打开 / 收起面板（交给 hover.sh，静音在面板里点）。
# 输出设备不支持调音量（如显示器的 DP / HDMI 音频）时显示 --。
case "$SENDER" in
    mouse.clicked) exec "$CONFIG_DIR/plugins/hover.sh" ;;
    mouse.scrolled)
        # Mos 的平滑滚动把滚轮一格拆成一串细小的滚动事件（有的位移为 0）：
        # 位移为 0 的不管，0.25 秒内只调一次，一格只算一格
        delta=${SCROLL_DELTA:-0}
        [ "$delta" -eq 0 ] 2>/dev/null && exit 0
        stamp="/tmp/yabai-aero-$USER/volume-scroll"
        now=$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')
        last=$(cat "$stamp" 2>/dev/null || echo 0)
        [ $((now - last)) -lt 250 ] && exit 0
        mkdir -p "$(dirname "$stamp")" && echo "$now" >"$stamp"
        step=5
        [ "$delta" -lt 0 ] && step=-5
        osascript -e "set volume output volume ((output volume of (get volume settings)) + $step)" ;;
esac

read -r volume muted < <(osascript -e 'set s to get volume settings' \
    -e 'return ((output volume of s) as text) & " " & ((output muted of s) as text)' 2>/dev/null)

if ! [[ "$volume" =~ ^[0-9]+$ ]]; then
    sketchybar --set "$NAME" icon=󰕾 label=--
elif [ "$muted" = true ] || [ "$volume" -eq 0 ]; then
    sketchybar --set "$NAME" icon=󰖁 label="${volume}%"
elif [ "$volume" -lt 34 ]; then
    sketchybar --set "$NAME" icon=󰕿 label="${volume}%"
elif [ "$volume" -lt 67 ]; then
    sketchybar --set "$NAME" icon=󰖀 label="${volume}%"
else
    sketchybar --set "$NAME" icon=󰕾 label="${volume}%"
fi
