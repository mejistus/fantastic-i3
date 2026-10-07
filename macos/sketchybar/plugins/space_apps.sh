#!/bin/bash
# 每个工作区上有哪些应用：数字后面跟它们的图标；空工作区的数字变暗、不显示图标。
# 窗口来自 yabai：只算普通窗口。yabai 刚启动时，还没去过的桌面上的窗口它拿不到细节（没有 AX 引用、
# 类型为空），分不清是真窗口还是"关了窗口但还在后台"的应用（如微信）留下的，这些一律算上。
export PATH=/opt/homebrew/bin:/usr/bin:/bin
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icon_map.sh"

windows=$(yabai -m query --windows 2>/dev/null) || exit 0
icons=()
while IFS=$'\t' read -r space app; do
    [ -n "$space" ] && [ "$space" -le 10 ] || continue
    __icon_map "$app"
    # 拿不到细节的窗口，yabai 报的是进程名（如 zotero），图标表里是 Zotero：首字母大写再查一次
    [ "$icon_result" = ":default:" ] && __icon_map "$(tr '[:lower:]' '[:upper:]' <<<"${app:0:1}")${app:1}"
    icons[space]+=" $icon_result"
done < <(jq -r '.[] | select(.subrole == "AXStandardWindow" or (."has-ax-reference" | not)) | "\(.space)\t\(.app)"' <<<"$windows" | sort -u)

args=()
for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ -n "${icons[i]}" ]; then
        args+=(--set "space.$i" label="${icons[i]# }" label.drawing=on icon.color="$FG")
    else
        args+=(--set "space.$i" label.drawing=off icon.color="$FG_FAINT")
    fi
done
sketchybar "${args[@]}"
