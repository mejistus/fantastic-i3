#!/usr/bin/env bash 
sensors | grep -IP 'Core\s*\d*:\s*\+\d*\.*\d*°C' | awk -F'[+°]' '{sum+=$2; count++} END {printf "%.1f°C\n", sum/count}'

