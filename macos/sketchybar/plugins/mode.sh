#!/bin/bash
# skhd 模式：进入 resize / service 模式时显示（skhdrc 里 :: 模式声明触发 skhd_mode，带 MODE=）
source "$CONFIG_DIR/colors.sh"
case "$MODE" in
    resize)  sketchybar --set "$NAME" drawing=on label=RESIZE background.color="$ORANGE" ;;
    service) sketchybar --set "$NAME" drawing=on label=SERVICE background.color="$PURPLE" ;;
    *)       sketchybar --set "$NAME" drawing=off ;;
esac
