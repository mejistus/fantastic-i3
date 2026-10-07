#!/bin/bash
# 配色和文字字体。彩色主题是 One Dark，底色和前景色与 polybar（../../polybar/color.ini）一致。格式 0xAARRGGBB。
# 主题：color（彩色）/ mono（黑白，像原生菜单栏：图标、文字、曲线都是白色，文字用系统字体，
#       只有表示警告的 WARN / ALERT 保留黄、红）。
# 栏最右边的开关（plugins/theme.sh）切换，记在 defaults 的 fantastic-i3.sketchybar theme 里（aero-helper 也读它）
export THEME=$(defaults read fantastic-i3.sketchybar theme 2>/dev/null || echo color)
export BAR_COLOR=0x00282c34   # 栏底色全透明：底色完全交给 aero-helper bar-backdrop 的底板（和原生菜单栏一样是模糊的壁纸）。
                              # 想更不透就加大前两位（00 → 40 → 80），叠一层 #282c34 的深色
export DARK=0xff282c34        # 彩色底上的深色字（skhd 模式标签）
export ITEM_BG=0xff3e4451     # 弹出面板的边框、分隔线、滑块底
export SPACE_BG=0x33ffffff    # 当前工作区的底色（半透明白，和原生菜单栏点开菜单时的高亮一样）
export FG=0xffeaeaea          # 主要文字
export FG_ALT=0xff9c9c9c      # 次要文字（窗口标题）
export FG_DIM=0xff5c6370      # 弹出面板里的提示行
export FG_FAINT=0x73ffffff    # 空工作区的数字（半透明白，玻璃底上也看得见）
export BLUE=0xff61afef
export GREEN=0xff98c379
export YELLOW=0xffe5c07b
export RED=0xffe06c75
export PURPLE=0xffc678dd
export CYAN=0xff56b6c2
export ORANGE=0xffd19a66
export GREEN_DIM=0xb398c379   # 网速的 ↓（淡一些，数字还是白的）
export RED_DIM=0xb3e06c75     # 网速的 ↑
export BLUE_FILL=0x4461afef   # CPU 曲线下面的填充
export PURPLE_FILL=0x44c678dd # GPU 曲线下面的填充
export WARN=0xffe5c07b        # 警告（黄）、严重（红）：电量低之类，两种主题都用
export ALERT=0xffe06c75

# 文字字体和四档字重（图标一直用 sketchybarrc 里的 Maple Mono NF 的字形），APP_NAME 是当前应用名的字重。
# PERCENT_GLYPH / RATE_GLYPH：这个字体下最宽的百分比（"40%"）、网速（"10.0M"）有多宽，sketchybarrc 用来定固定宽度
export TEXT_FONT="Maple Mono NF" BOLD=Bold SEMIBOLD=SemiBold MEDIUM=Medium REGULAR=Regular APP_NAME=SemiBold
export PERCENT_GLYPH=23 RATE_GLYPH=35

if [ "$THEME" = mono ]; then
    # 黑白：文字纯白，强调色都换成白，箭头、曲线填充用半透明白
    export FG=0xffffffff FG_ALT=0xb3ffffff
    export BLUE=$FG GREEN=$FG YELLOW=$FG RED=$FG PURPLE=$FG CYAN=$FG ORANGE=$FG
    export GREEN_DIM=0x99ffffff RED_DIM=0x99ffffff BLUE_FILL=0x33ffffff PURPLE_FILL=0x33ffffff
    # 系统字体（和原生菜单栏一样，中文自动用苹方），字重比 Maple Mono 降一档；数字由 sketchybarrc 设成等宽（tnum）
    export TEXT_FONT=.AppleSystemUIFont BOLD=Semibold SEMIBOLD=Medium MEDIUM=Regular REGULAR=Regular APP_NAME=Bold
    export PERCENT_GLYPH=28 RATE_GLYPH=34
fi
