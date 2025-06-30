#!/usr/bin/bash

# 获取参数，默认为next
direction=${1:-next}

# 根据参数决定加减
if [[ $direction == "prev" ]]; then
    operator="-"
else
    operator="+"
fi

i3-msg workspace $(python -c "print(($(~/.config/i3/i3-next-available-workspace.py )${operator}1)%10)")
