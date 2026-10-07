#!/bin/bash
# 主题开关（栏最右边）：点一下在彩色（color）和黑白（mono）之间切换。
# 记在 defaults 的 fantastic-i3.sketchybar theme 里，然后重新加载 SketchyBar：colors.sh 按它定颜色，
# aero-helper bar-stats 也跟着重启、按它给弹出面板上色。
# 只认点击：sketchybarrc 最后的 sketchybar --update 会让每一项的脚本都跑一次（SENDER=forced），不挡掉就会一直切换、重新加载
[ "$SENDER" = mouse.clicked ] || exit 0
current=$(defaults read fantastic-i3.sketchybar theme 2>/dev/null || echo color)
[ "$current" = mono ] && next=color || next=mono
defaults write fantastic-i3.sketchybar theme -string "$next"
sketchybar --reload
