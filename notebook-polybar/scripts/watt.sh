#!/bin/bash

BATTERY="/sys/class/power_supply/BAT0"

if [[ -f "$BATTERY/current_now" && -f "$BATTERY/voltage_now" ]]; then
    CURRENT=$(cat "$BATTERY/current_now")  # μA
    VOLTAGE=$(cat "$BATTERY/voltage_now")  # μV
    # W = (μA * μV) / 1e12
    RATE=$(echo "scale=1; $CURRENT * $VOLTAGE / 1000000000000" | bc)
    echo "❖ $RATE" W
elif command -v upower &>/dev/null; then
    BAT_PATH=$(upower -e | grep battery | head -n1)
    RATE_W=$(upower -i "$BAT_PATH" | grep "energy-rate" | awk '{print $2}')
    echo "❖ $RATE_W" W
else
    echo "Cannot detect battery power rate."
fi
