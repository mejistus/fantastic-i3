#!/bin/bash
# 工作区按钮：点一下切过去；当前工作区高亮（space_change 时 SketchyBar 给每个 space 项设好 $SELECTED）
if [ "$SENDER" = mouse.clicked ]; then
    exec "$HOME/Documents/fantastic-i3/macos/yabai/aero" workspace "${NAME#space.}"
fi
sketchybar --set "$NAME" icon.highlight="$SELECTED" label.highlight="$SELECTED" background.drawing="$SELECTED"
