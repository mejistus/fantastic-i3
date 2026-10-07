#!/bin/bash
# 音量弹出面板里的滑块：点 / 拖到哪里，音量就设成多少（SketchyBar 给出 $PERCENTAGE）
if [ "$SENDER" = mouse.clicked ] && [ -n "$PERCENTAGE" ]; then
    sketchybar --set "$NAME" slider.percentage="$PERCENTAGE"
    osascript -e "set volume output volume $PERCENTAGE"
fi
