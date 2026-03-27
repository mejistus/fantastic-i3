mpd --no-daemon &
bash $HOME/.config/polybar/launch.sh 
/usr/bin/cfw &
notify-send -t 3000 -i /usr/share/faces/markov.face.icon "Hello, Asahi" &
feh --bg-fill /usr/share/backgrounds/backgound &
fcitx5 -r &
clipit &
i3-auto-tiling &
i3-auto-layout &
bash $HOME/.config/i3/NIC.sh
xset r rate 300 50& 
xset -dpms
xset s off
picom &
