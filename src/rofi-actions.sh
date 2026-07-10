#!/usr/bin/env bash

# Rofi action menu: pick an item, run its command.
# Add new entries as "Label|command" lines below.

ROFI_ACTIONS_RC="${ROFI_ACTIONS_RC:-$HOME/.config/rofiactionsrc}"
[ -f "$ROFI_ACTIONS_RC" ] && readarray -t more_actions < <(grep -Ev '(^$)|(^[ \t]*#.*$)' "$ROFI_ACTIONS_RC" | sed ':a;N;$!ba;s/\\\n/ /g;' | envsubst)


declare -a actions=(
    # configuration
    " Toggle statusbar widgets|statusbar-config"
    " Toggle i3 bar|i3-msg bar mode toggle"
    " Reload i3|i3-msg reload"
    " Restart i3|i3-msg restart"
    "󱕷 Config i3|$TERMINAL -c floating -e $EDITOR $HOME/.config/i3/config"
    "󱍱 Config|vimcfg -c -F"
    " Config system|vimcfg -e -F"
    "󱙨 Config dotfiles|vimcfg  -F"

    # capture / clipboard
    "󰹑 Screenshot (gui)|flameshot gui"
    "󰹑 Screenshot (full)|flameshot full"
    "󰅌 Clipboard history|clipmenu"
    "󱘝 Clear clipboard history|clipdel -d '.*'"

    # homelab
    "󰟐 Home Assistant|xdg-open https://ha.home.local/dashboard-dashboard/0"
    "󰐫 3D Printer|xdg-open https://ha.home.local/dashboard-dashboard/0"

    # input / display
    " Toggle keyboard layout|kblang -l us,rs-latin,rs -t"
    "󰨇 Screen layout|screenlayout"
    "󰸉 Wallpaper picker|setwal"
    " Random wallpaper|setwal -R"

    # audio / network / bluetooth
    " Audio control|pavucontrol"
    "󱡫 Toggle default sink|padefault toggle"
    " Network connections|nm-connection-editor"
    "󰂯 Bluetooth manager|blueman-manager"

    # notifications
    "󰎟 Dismiss notification|dunstctl close"
    " Notification history|dunstctl history-pop"
    " Toggle notifications|dunstctl set-paused toggle"

    # apps / launchers
    " Game launcher|rofi-lutris"
    " Bookmarks|bks"
    " Browser profile|browser-profile"

    # utilities
    "󰸉 Reload wallpaper|nitrogen --restore"
    "󰚰 System update|$TERMINAL -c floating -e yay -Syyu"
    "󰒍 Update mirrorlist|$TERMINAL -c floating -e sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
    " Task manager|$TERMINAL -c floating -e sh -c 'if command -v btop >/dev/null 2>&1; then exec btop; else exec htop; fi'"
    " Color picker|colorpick"
    " Kill port process|portkill"
    "󰃭 Today's agenda|today"
    "󰀠 Wake on LAN|wolsel"
    "󰝳 Reset USB controllers|usb-reload"
    "󰌏 Unstuck mod keys|xdotool keyup Shift_L Shift_R Control_L Control_R Alt_L Alt_R Super_L Super_R Hyper_L Hyper_R Caps_Lock 204 205 206 207"
    " Edit actions file|$TERMINAL -c floating -e $EDITOR $HOME/.config/rofiactionsrc"
    "󰃰 Edit crontab|$TERMINAL -c floating -e crontab -e"
    "󰃰 Edit system crontab|$TERMINAL -c floating -e pkexec crontab -e"

    # session / power
    "󰌾 Lock screen|i3exit lock"
    "󰒲 Suspend|i3exit suspend"
    "󰗽 Logout|i3exit logout"
    "󱄌 Reboot|i3exit reboot"
    "⏻ Shutdown|i3exit shutdown"
)
if [ ${#more_actions[@]} -gt 0 ]; then
    actions+=("${more_actions[@]}")
fi

menu="rofi -dmenu -i -p Actions"
if [ -t 1 ]; then
    menu="fzf"
fi

choice=$(printf '%s\n' "${actions[@]}" | cut -d'|' -f1 | $menu) || exit 0
[ -z "$choice" ] && exit 0

for entry in "${actions[@]}"; do
    label=${entry%%|*}
    cmd=${entry#*|}
    if [ "$label" = "$choice" ]; then
        exec sh -c "$cmd"
    fi
done
