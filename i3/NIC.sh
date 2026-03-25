#!/bin/bash
# ~/.config/i3/choose_netcard.sh

NETWORK_INI="$HOME/.config/polybar/modules/network.ini"

# get the first matched interface
get_interface() {
    local pattern=$1
    ip link show | grep -oP "(?<=\d: )${pattern}[^:@]+" | head -1
}

iface=$(get_interface "enp")
[ -z "$iface" ] && iface=$(get_interface "wlan")
[ -z "$iface" ] && iface="enp"  # fallback

sed -i "s/^interface = .*/interface = $iface/" "$NETWORK_INI"
