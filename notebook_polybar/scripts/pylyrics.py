#!/usr/bin/env python3
import re
import time
import os
import sys
import bisect
from subprocess import check_output


def parse_lrc(file_path):
    lyrics = []
    with open(file_path, "r", encoding="utf-8") as file:
        current_language_lyrics = []
        for line in file:
            match = re.match(r"\[(\d+):(\d+)\.(\d+)\](.*)", line)
            if match:
                minutes, seconds, millis, text = match.groups()
                timestamp = int(minutes) * 60 + \
                    int(seconds) + int(millis) / 1000
                if text.strip():  # 排除空行
                    current_language_lyrics.append((timestamp, text.strip()))
            elif line.strip() == "":  # 遇到空行表示可能切换到下一个语种部分
                if current_language_lyrics:
                    lyrics.extend(current_language_lyrics)
                    break  # 只添加第一个语种的歌词
        if not lyrics and current_language_lyrics:
            lyrics = current_language_lyrics  # 如果没有空行分割，使用所有歌词
    return lyrics


# 获取当前播放时间和歌曲名称
def get_current_song_info():
    status = check_output(["mpc", "status"]).decode("utf-8")
    if "[playing]" in status:
        song_info = check_output(["mpc", "current"]).decode("utf-8").strip()
        # print(f"song_info:{song_info}")
        match = re.search(r"(\d+):(\d+)/(\d+):(\d+)", status)
        if match:
            current_minutes, current_seconds, _, _ = map(int, match.groups())
            current_time = current_minutes * 60 + current_seconds
            return song_info, current_time
    return None, None


# 从歌曲信息中提取歌名和艺术家
def extract_song_name_and_artist(song_info):
    match = re.match(r"(.+?) - (.+)", song_info)
    if match:
        song_name, artist = match.groups()
        return song_name, artist
    return song_info, ""


# 模糊查找LRC文件
def find_lrc_file(directory, song_name, artist):
    for root, _, files in os.walk(directory):
        # print(files)
        for file in files:
            if file.endswith(".lrc"):
                # 歌名和歌手分别模糊匹配
                # print(song_name,file)
                if song_name.lower() in file.lower():
                    # print(root,file)
                    return os.path.join(root, file)
    return None


# 根据歌曲进度从lyrics中选出当前正在播放的歌词
def display_lyrics(lyrics, current_time):
    lyrics_id = bisect.bisect_left(
        [timestamp for timestamp, text in lyrics], current_time
    )
    return lyrics[max(0, lyrics_id - 1)][1]


def main():
    song_info, curtime = get_current_song_info()
    if song_info is None:
        return
    song_name, artist = extract_song_name_and_artist(song_info)
    # print(f"song_name,artist={song_name, artist}")
    # 查找LRC文件
    lrc_directory = os.path.expanduser("~/Music/LX-Music")
    lrc_file_path = find_lrc_file(lrc_directory, song_name, artist)
    if lrc_file_path:
        # 解析并显示歌词
        lyrics = parse_lrc(lrc_file_path)
        print(display_lyrics(lyrics, curtime), file=sys.stdout)
    else:
        print(f"{song_name}", file=sys.stdout)


if __name__ == "__main__":
    main()
