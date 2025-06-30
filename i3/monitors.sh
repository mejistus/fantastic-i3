# xrandr --output HDMI-A-0 --same-as eDP &
# xrandr --output HDMI-2 --mode 2560x1440 --scale-from 2160x1440 --rate 60 --same-as eDP-1 --noprimary
# xrandr --output DP-1 --mode 2560x1440 --rate 165 --primary
# extended join
# xrandr --output HDMI-1  --mode 2560x1440 --rate 144 --below DP-1
xrandr --output HDMI-1  --mode 2560x1440 --rate 144 --primary
# xrandr --output eDP-1 
# xrandr --output HDMI-2 
# xrandr --output HDMI-1 
# xrandr --output DP-1
# mirrored
# xrandr --output HDMI-1  --mode 2560x1440 --rate 60 --same-as eDP-1
# xrandr --output HDMI-2 --same-as eDP-1 
xset s off
xset -dpms
