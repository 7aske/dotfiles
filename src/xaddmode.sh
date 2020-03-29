#!/usr/bin/env sh

output="$(xrandr | grep ' connected primary' | awk '{print $1}')"

[ -z "$output" ] && echo "Unable to get primary output" && exit 1

# defaults
height="1080"
width="1920"

if [ -n "$1" ] && [ -n "$2" ]; then
    width="$1"
    height="$2"
fi

modename="${width}x${height}"
modeline="$(gtf "$width" "$height" 60 | grep 'Modeline ' | awk '{$1 = ""; $2 =""; print $0}')"

echo "$modename$modeline"

echo "$modename$modeline" | xargs xrandr --newmode && echo "Added $modename"

xrandr --addmode "$output" "$modename" && echo "Added $modename to $output"

xrandr --output "$output" --mode "$modename" && echo "Setting resolution of $output to $modename"
