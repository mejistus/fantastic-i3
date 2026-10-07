#!/bin/bash
# 日期时间，按系统的语言和地区格式化（现在是 zh-Hant：10月7日 週三 13:55）
# 点击：交给 hover.sh（打开 / 收起面板）
case "$SENDER" in
    mouse.clicked) exec "$CONFIG_DIR/plugins/hover.sh" ;;
esac
sketchybar --set "$NAME" label="$("$HOME/.cache/fantastic-i3/aero-helper" date MMMdEEEHm)"
