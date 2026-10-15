bash $HOME/.config/polybar/launch.sh
mpd &
/usr/bin/cfw &
notify-send -t 3000 -i /usr/share/faces/markov.face.icon "Hello, Asahi" &
feh --bg-fill /usr/share/backgrounds/backgound &
fcitx5 -r &
eval $(gnome-keyring-daemon --start --components=secrets) >/dev/null 2>&1
clipit &
i3-auto-tiling &
bash $HOME/.config/i3/NIC.sh
xset r rate 300 50 &
xset -dpms
xset s off
picom &
sleep 2
bash $HOME/.config/polybar/launch.sh
