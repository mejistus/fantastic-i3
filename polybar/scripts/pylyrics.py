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
                if text.strip():  
                    current_language_lyrics.append((timestamp, text.strip()))
            elif line.strip() == "":   # use first perferred language 
                if current_language_lyrics:
                    lyrics.extend(current_language_lyrics)
                    break 
        if not lyrics and current_language_lyrics:
            lyrics = current_language_lyrics  # just use all
    return lyrics 
## test done


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
# test done 

def extract_song_name_and_artist(song_info):
    match = re.match(r"(.+?) - (.+)", song_info)
    if match:
        song_name, artist = match.groups()
        return song_name, artist
    return song_info, ""

# no work for some songs file because name-artist and artist-name both exists.

def find_lrc_file(directory, song_name, artist):
    for root, _, files in os.walk(directory):
        # print(files)
        for file in files:
            if file.endswith(".lrc"):
                # print(song_name,file)
                if song_name.lower() in file.lower():
                    # print(root,file)
                    return os.path.join(root, file)
    return None
# test done 

def display_lyrics(lyrics, current_time):
    lyrics_id = bisect.bisect_left(
        [timestamp for timestamp, text in lyrics], current_time
    )
    return lyrics[max(0, lyrics_id - 1)][1]

# test done

def main():
    song_info, curtime = get_current_song_info()
    if song_info is None:
        return
    song_name, artist = extract_song_name_and_artist(song_info)
    # print(f"song_name,artist={song_name, artist}")
    lrc_directory = os.path.expanduser("~/Music/LX-Music") ## Maybe more friendly
    lrc_file_path = find_lrc_file(lrc_directory, song_name, artist)
    if lrc_file_path:
        lyrics = parse_lrc(lrc_file_path)
        print(display_lyrics(lyrics, curtime), file=sys.stdout)
    else:
        print(f"{song_name}", file=sys.stdout)


if __name__ == "__main__":
    main()
