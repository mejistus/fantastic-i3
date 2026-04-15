#!/bin/bash

# 检查是否传递了窗口长度参数
window_length=${1:-15}
# 获取窗口长度参数
# 获取当前播放的歌曲名称，并去除文件后缀
song=$(mpc current | sed -E 's/\.[a-zA-Z0-9]+$//')

# 如果没有歌曲在播放，设置默认显示内容
if [ -z "$song" ]; then
    echo "❖"
    exit 0
fi

# 获取歌曲名称的长度
song_length=${#song}

# 如果歌曲名称长度小于或等于窗口长度，直接打印歌曲名称
if [ $song_length -le $window_length ]; then
    echo "$song"
    exit 0
fi

# 获取当前歌曲的播放进度（秒）
current_position=$(mpc status | grep -oP '\d+:\d+/\d+:\d+' | cut -d '/' -f 1 | awk -F: '{ print ($1 * 60) + $2 }')

# 计算当前偏移量，确保从0开始
offset=$(( current_position % (song_length + window_length / 2) ))

# 构建滚动显示的字符串，包括窗口长度一半的空格
scroll_song="$song$(printf '%*s' $((window_length / 2)))"

# 根据当前偏移量截取窗口长度的子字符串
output="${scroll_song:offset:window_length}"

# 如果子字符串长度不足窗口长度，补充空白
if [ ${#output} -lt $window_length ]; then
    output+="${scroll_song:0:window_length-${#output}}"
fi

# 打印输出到 Polybar
echo "$output"

