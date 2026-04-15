#!/bin/env python3
import os
import sys
import re
import subprocess

polybar = os.path.join(os.getenv("HOME"), ".config/polybar") 
config = os.path.join(polybar, "module_list.ini")
mode_dict={
    1:"*",
    2:"*",
    3:"*"
}

def get_current_config_id():
    with open(config, "r") as f:
        (content := f.read())
    return int(re.search(r"c(\d+)\.ini", content).group(1))


def circle():
    style_id = get_current_config_id()
    length = len(os.listdir(os.path.join(polybar, "combination")))
    style_id = (style_id % length) + 1

    with open(config, "w") as w:
        w.write(
            f"include-file = ~/.config/polybar/combination/current\n"
        )


def select(n):
    length = len(os.listdir(os.path.join(polybar, "combination")))
    if not 0 < n <= length:
        return

    with open(config, "w") as f:
        f.write(
            f"include-file = ~/.config/polybar/combination/current\n"
        )


if __name__ == "__main__":
    sys.stdout.write(f"{mode_dict[get_current_config_id()]}")
    if len(sys.argv) > 1:
        match sys.argv[1].strip("-"):
            case "next":
                circle()
            case "select":
                n = int(sys.argv[2]) if len(sys.argv) > 2 else 1
                select(n)

# print(config_wrapper(load_default_module_list()))
