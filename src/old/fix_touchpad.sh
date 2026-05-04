#!/usr/bin/env sh

TAP="Tapping Enabled ("
TAP_DRAG="Tapping Drag Enabled ("
NAT_SCROLL="Natural Scrolling Enabled ("
MID_EMUL="Middle Emulation Enabled ("
ACC_SPD="Accel Speed ("

ID=$(xinput list | grep Touchpad | awk '{print $6}' | sed -e 's/id=//')

[ -z "$ID" ] && exit 1

TAP_PROP=$(xinput list-props "$ID" | grep "$TAP" | awk -F '[()]' '{print $2}')
TAP_DRAG_PROP=$(xinput list-props "$ID" | grep "$TAP_DRAG" | awk -F '[()]' '{print $2}')
NAT_SCROLL_PROP=$(xinput list-props "$ID" | grep "$NAT_SCROLL" | awk -F '[()]' '{print $2}')
MID_EMUL_PROP=$(xinput list-props "$ID" | grep "$MID_EMUL" | awk -F '[()]' '{print $2}')
ACC_SPD_PROP=$(xinput list-props "$ID" | grep "$ACC_SPD" | awk -F '[()]' '{print $2}')

xinput set-prop "$ID" "$TAP_PROP" 1
xinput set-prop "$ID" "$TAP_DRAG_PROP" 1
xinput set-prop "$ID" "$NAT_SCROLL_PROP" 1
xinput set-prop "$ID" "$MID_EMUL_PROP" 1
xinput set-prop "$ID" "$ACC_SPD_PROP" 0.5
