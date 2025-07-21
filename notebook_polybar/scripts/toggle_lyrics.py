#!/bin/env python3
import sys
import subprocess
import os

work_dir = os.path.join(os.getenv("HOME"), ".config/polybar/scripts")
lyrics_status_file = os.path.join(work_dir, ".lyrics_status")


def show_lyrics():
    subprocess.Popen(
        [
            "ln",
            "-sf",
            os.path.join(work_dir, "pylyrics.py"),
            os.path.join(work_dir, "player"),
        ],
    )
    with open(lyrics_status_file, "w") as f:
        f.write("on")


def show_song_info():
    subprocess.Popen(
        [
            "ln",
            "-sf",
            os.path.join(work_dir, "mpc-scroll.sh"),
            os.path.join(work_dir, "player"),
        ]
    )
    with open(lyrics_status_file, "w") as f:
        f.write("off")


def toggle():
    if status():
        show_song_info()
    else:
        show_lyrics()


def status():
    if not os.path.exists(lyrics_status_file):
        return False
    with open(lyrics_status_file, "r") as f:
        (status := f.read().strip().lower())
    return True if status == "on" else False


if __name__ == "__main__":
    match sys.argv[1]:
        case "on":
            show_lyrics()

        case "off":
            show_song_info()

        case "toggle":
            toggle()

        case "status":
            print('on' if status() else 'off')
