#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"

case $BLOCK_BUTTON in
    1) notify-send -i cpu "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
    2) if [ -e "$SWITCH" ]; then rm "$SWITCH"; else touch "$SWITCH"; fi ;;
    3) wtoggle2 -T htop 2>/dev/null 1>/dev/null ;;
esac

# Two samples from /proc/stat (~150ms) instead of mpstat 1 1 (~1s).
cpu_usage_from_proc() {
    read -r _ u1 n1 s1 i1 io1 irq1 sirq1 steal1 _ < /proc/stat
    sleep 0.15
    read -r _ u2 n2 s2 i2 io2 irq2 sirq2 steal2 _ < /proc/stat

    idle1=$((i1 + io1))
    idle2=$((i2 + io2))
    nonidle1=$((u1 + n1 + s1 + irq1 + sirq1 + steal1))
    nonidle2=$((u2 + n2 + s2 + irq2 + sirq2 + steal2))
    total1=$((idle1 + nonidle1))
    total2=$((idle2 + nonidle2))
    totald=$((total2 - total1))
    idled=$((idle2 - idle1))

    if [ "$totald" -le 0 ]; then
        echo 0
        return
    fi
    echo $(( (100 * (totald - idled)) / totald ))
}

cpu_usage="$(cpu_usage_from_proc)"

if [ "$cpu_usage" -ge 75 ]; then
    icon="󰡴"
    color="${color1:-"#BF616A"}"
elif [ "$cpu_usage" -ge 50 ]; then
    icon="󰊚"
    color="${color3:-"#D08770"}"
elif [ "$cpu_usage" -ge 25 ]; then
    icon="󰡵"
    color="${color2:-"#EBCB8B"}"
else
    icon="󰡳"
    color="${color7:-"#D8DEE9"}"
fi

if [ -e "$SWITCH" ]; then
    printf "<span color='%s' size='large'>%s </span>\n" "$color" "$icon"
else
    printf "<span size='large'>$icon</span> <span color='%s'>%3d%%</span>\n" "$color" "$cpu_usage"
fi
