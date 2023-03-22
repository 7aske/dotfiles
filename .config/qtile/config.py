import os
import platform
import re
import subprocess
from abc import ABC, abstractmethod
from typing import List, Union

import psutil
from libqtile.log_utils import logger

from libqtile import bar, layout, widget
from libqtile import hook, qtile
from libqtile.config import Drag, Group, Key, KeyChord, Match, Screen, \
    ScratchPad, DropDown, Rule
from libqtile.lazy import lazy
from qtile_extras import widget as qtile_extras_widget
from qtile_extras.widget.decorations import RectDecoration

#  _____ _   ___     _____      _    _     ___    _    ____  _____ ____
# | ____| \ | \ \   / ( _ )    / \  | |   |_ _|  / \  / ___|| ____/ ___|
# |  _| |  \| |\ \ / // _ \/\ / _ \ | |    | |  / _ \ \___ \|  _| \___ \
# | |___| |\  | \ V /| (_>  </ ___ \| |___ | | / ___ \ ___) | |___ ___) |
# |_____|_| \_|  \_/  \___/\/_/   \_\_____|___/_/   \_\____/|_____|____/
# @formatter:off -------------------------------------------------------
MOD   =    "mod4"
ALT   =    "mod1"
SHIFT =   "shift"
CTRL  = "control"

MOUSE_LEFT   = "Button1"
MOUSE_MIDDLE = "Button2"
MOUSE_RIGHT  = "Button3"
SCROLL_UP    = "Button4"
SCROLL_DOWN  = "Button5"

SCRATCHPAD = "scratchpad"

TERMINAL = os.getenv("TERMINAL", "xterm")
BROWSER  = os.getenv("BROWSER",  "firefox")
MAIL     = os.getenv("MAIL",     "thunderbird")
READER   = os.getenv("READER",   "zathura")
PLAYER   = os.getenv("PLAYER",   "spotify")
FILE     = os.getenv("FILE",     "thunar")
TERMFILE = os.getenv("TERMFILE", "ranger")
EDITOR   = os.getenv("EDITOR",   "vim")
CALENDAR = os.getenv("CALENDAR", "calcurse")

CODEOPEN_MENU  = "rofi"
FONT           = "Fira Code Medium"
DMENU_FONT     = "Fira Code Medium-12"
FONT_SIZE      =   12
GAPS_SIZE      =   20
NOTIF_DURATION = 1000
BAR_HEIGHT     =   32
# @formatter:on


#  _   _ _____ ___ _     ___ _______   __
# | | | |_   _|_ _| |   |_ _|_   _\ \ / /
# | | | | | |  | || |    | |  | |  \ V /
# | |_| | | |  | || |___ | |  | |   | |
#  \___/  |_| |___|_____|___| |_|   |_|
def in_terminal(command: Union[List[str], str]):
    """
    Format a command to be executed in a terminal.

    :param command: Command to be executed in a terminal.
    :return: Formatted command.
    """
    if isinstance(command, str):
        command = [command]
    return TERMINAL + ' -e ' + " ".join(command)


def in_float_terminal(command: Union[List[str], str]):
    """
    Format a command to be executed in a floating terminal.

    :param command: Command to be executed in a terminal.
    :return: Formatted command.
    """
    if isinstance(command, str):
        command = [command]
    return TERMINAL + " -c floating " + ' -e ' + " ".join(command)


def scratchpad_toggle(name: str, scratchpad=SCRATCHPAD):
    """
    Toggle a scratchpad app.
    :param name: Name of the scratchpad app.
    :param scratchpad: Name of the scratchpad. Default is SCRATCHPAD.
    """
    return lazy.group[scratchpad].dropdown_toggle(name)


def notification(text: str, title='Qtile', icon='dialog-information',
                 priority='normal'):
    """
    Send a notification using the `notify-send` command.
    """
    return f"notify-send -i \"{icon}\" -u \"{priority}\" \"{title}\" \"{text}\""


def get_widget(name):
    """
    Get a widget by name.
    """
    return lazy.widget[name]


def center(width: float, height: float) -> dict:
    """
    Generate coordinates along with width and height to center a window.
    """
    return dict(
        y=(1 - height) / 2,
        x=(1 - width) / 2,
        height=height,
        width=width
    )


def group_to_prev_screen(q):
    """
    Move the current group to the previous screen.
    """
    current_screen = qtile.screens.index(q.current_screen)
    prev_screen = (current_screen - 1) % len(q.screens)
    q.screens[current_screen].group.cmd_toscreen(screen=prev_screen)
    q.cmd_prev_screen()


def group_to_next_screen(q):
    """
    Move the current group to the next screen.
    """
    current_screen = q.screens.index(q.current_screen)
    next_screen = (current_screen + 1) % len(q.screens)
    q.screens[current_screen].group.cmd_toscreen(screen=next_screen)
    q.cmd_next_screen()


def update_widget(name):
    """
    Update a widget.
    """
    return lazy.widget[name].cmd_force_update()


def update_widget_shell(name):
    """
    Update a widget.
    """
    return "qtile cmd-obj -o widget " + name + " -f eval -a 'self.cmd_force_update()'"


def focus_group_by_name(name):
    """
    Factory method for a focus group by name function that preserves the
    groups current screen if present.
    """

    def inner(q):
        """
        Inner function to be passed to the qtile command object. Captures the
        name of the group to focus.
        """
        for group in qtile.groups:
            if group.name != name:
                continue

            current_screen_index = q.screens.index(q.current_screen)
            if group.screen:
                idx = group.screen.index
                # If current screen is not that of the group we want to focus
                # we first need to switch to that screen.
                if current_screen_index != idx:
                    q.cmd_to_screen(idx)

                return group.cmd_toscreen(screen=idx)

            # If the group has no screen that means that it is not visible
            # on any of the screens.
            idx = q.screens.index(q.current_screen)
            if group.last_screen:
                idx = group.last_screen.index
            return group.cmd_toscreen(screen=idx)

        # No-op if group not found.
        # Shouldn't reach this anyway.
        return lambda: None

    return inner


# ____      _
#  / ___|___ | | ___  _ __ ___
# | |   / _ \| |/ _ \| '__/ __|
# | |__| (_) | | (_) | |  \__ \
#  \____\___/|_|\___/|_|  |___/
# @formatter:off
color0  = "#2E3440"
color1  = "#3B4252"
color2  = "#434C5E"
color3  = "#4C566A"
color4  = "#D8DEE9"
color5  = "#E5E9F0"
color6  = "#ECEFF4"
color7  = "#8FBCBB"
color8  = "#88C0D0"
color9  = "#81A1C1"
color10 = "#5E81AC"
color11 = "#BF616A"
color12 = "#D08770"
color13 = "#EBCB8B"
color14 = "#A3BE8C"
color15 = "#B48EAD"
foreground  = color4
background  = color0
transparent = "#00000000"
# @formatter:on

#  _  __          _     _           _
# | |/ /___ _   _| |__ (_)_ __   __| |___
# | ' // _ \ | | | '_ \| | '_ \ / _` / __|
# | . \  __/ |_| | |_) | | | | | (_| \__ \
# |_|\_\___|\__, |_.__/|_|_| |_|\__,_|___/
#           |___/
# @formatter:off
keys = [
    Key([], "F1", desc="No Op"),
    Key([MOD],        "q",    lazy.window.kill(),                             desc="Launch terminal"),
    Key([MOD, SHIFT], "r",    lazy.restart(),                                 desc="Restart QTile"),
    Key([MOD, SHIFT], "c",    lazy.reload_config(),                           desc="Reload config"),
    Key([MOD],        "c",    lazy.window.center(),                           desc="Center floating window"),
    Key([MOD],        "u",    lazy.next_urgent(),                             desc="Next urgent window"),

    Key([MOD],        "Return",    lazy.spawn(TERMINAL),                             desc="Launch terminal"),
    Key([MOD, SHIFT], "Return",    scratchpad_toggle(TERMINAL), desc="Dropdown terminal"),
    Key([MOD],        "a",         lazy.spawn("rofi -show run"),                     desc="Launch rofi"),
    Key([MOD],        "d",         lazy.spawn("rofi -show drun"),                    desc="Launch rofi drun"),
    Key([MOD, SHIFT], "semicolon", lazy.spawn(f"dmenu_run -p ':' -f -b -fn '{DMENU_FONT}'"), desc="Launch dmenu"),
    Key([MOD],        "grave",     lazy.spawn(in_terminal("htop")),                  desc="Launch htop"),

    KeyChord([MOD, CTRL], "c", [
        Key([], "e", lazy.spawn("vimcfg --etc"),                                        desc="(e)tc"),
        Key([], "h", lazy.spawn("vimcfg --home"),                                       desc="(h)ome"),
        Key([], "c", lazy.spawn("vimcfg --config"),                                     desc="(c)onfig"),
        Key([], "d", lazy.spawn("vimcfg"),                                              desc="(d)efault"),
        Key([], "q", lazy.spawn("pycharm $CODE/sh/dotfiles/.config/qtile", shell=True), desc="(q)tile"),
    ], name="config"),

    Key([MOD],             "e",    lazy.spawn(in_terminal(TERMFILE)),        desc="Launch terminal file manager"),
    Key([MOD, SHIFT],      "e",    lazy.spawn(FILE),                         desc="Launch file manager"),
    Key([MOD],             "w",    lazy.spawn(BROWSER),                      desc="Launch default browser"),
    Key([MOD, SHIFT],      "w",    lazy.spawn(BROWSER + " --incognito"),     desc="Launch default browser in incognito mode"),
    Key([MOD, SHIFT],      "v",    lazy.spawn(in_terminal(EDITOR)),          desc="Launch default editor in terminal"),

    Key([MOD, ALT],        "n",    lazy.widget["notificationwidget"].toggle_paused(), desc="Pause notifications"),
    Key([MOD, SHIFT, ALT], "n",    lazy.spawn("dunst_reload"),                        desc="Reload notification daemon"),
    Key([MOD],             "n",    lazy.spawn("dunstctl context"),                    desc="Activate notification"),
    Key([MOD, CTRL],       "n",    lazy.spawn("dunstctl close"),                      desc="Close most recent notification"),
    Key([MOD, SHIFT],      "n",    lazy.spawn("dunstctl history-pop"),                desc="Show last notification"),

    Key([MOD],        "F10", lazy.spawn("echo 0 | dmenu -p 'screen: ' -fn '$dmenu_font' | xargs screencam -n", shell=True), desc="Start screen recording"),
    Key([MOD, SHIFT], "F10", lazy.spawn("env BLOCK_BUTTON=1 ~/.local/bin/statusbar/rec-status", shell=True), desc="Stop recording"),

    Key([MOD],             "semicolon", lazy.spawn(f"tmux list-sessions | cut -d: -f1 | rofi -dmenu -p session | xargs -I% -r {TERMINAL} -c tmux_floating -e tmux a -t '%'", shell=True), desc="Launch tmux session selector"),
    Key([MOD, ALT],        "semicolon", lazy.spawn(f"rofi -dmenu -p 'new session' | xargs -I% -r {TERMINAL} -c tmux_floating tmux new -s '%'", shell=True), desc="Launch tmux session creator"),

    Key([MOD, ALT],        "t",   lazy.spawn("transmission-gtk"),         desc="Launch transmission"),
    Key([MOD, ALT],        "l",   scratchpad_toggle("lutris"),            desc="Launch lutris"),
    Key([MOD, ALT, SHIFT], "d",   lazy.spawn("gnome-disks"),              desc="Launch gnome-disks"),
    Key([MOD, ALT],        "b",   scratchpad_toggle("bitwarden-desktop"), desc="Launch bitwarden"),
    Key([MOD, ALT],        "m",   scratchpad_toggle(MAIL),                desc="Launch mail"),
    Key([MOD, ALT],        "y",   lazy.spawn("vncviewer"),                desc="Launch vncviewer"),
    Key([MOD, ALT, SHIFT], "b",   lazy.spawn("virtualbox"),               desc="Launch virtualbox"),
    Key([MOD, ALT],        "d",   lazy.spawn("discord"),                  desc="Launch discord"),
    Key([MOD, ALT],        "k",   scratchpad_toggle("calendar"),          desc="Launch calendar"),

    # FIXME not using this anyway (use in_floating_terminal)
    # Key([MOD, ALT], "r",          lazy.spawn("$terminal -c newsboat_float -e newsboat"), desc="Launch newsboat"),
    # Key([MOD, ALT, CTRL], "r",    lazy.spawn("$terminal -c newsboat_float -e podboat"), desc="Launch podboat"),

    Key([MOD], "Scroll_Lock",     scratchpad_toggle("bitwarden-desktop"), desc="Launch bitwarden"),
    Key([MOD], "Pause",       	  lazy.spawn("sleep 1 && xset dpms force off", shell=True), desc="Turn off screen"),

    Key([],           "Print", lazy.spawn(f"maim ~/$(date +%s).png && notify-send -i screengrab --hint=int:transient:1 -t {NOTIF_DURATION} 'screenshot' 'saved to homedir'", shell=True), desc="Take screenshot"),
    Key([MOD],        "Print", lazy.spawn(f"maim -i $(xdotool getactivewindow) ~/$(date +%s).png && notify-send -i screengrab --hint=int:transient:1 -t {NOTIF_DURATION} 'screenshot (window)' 'saved to homedir'", shell=True), desc="Take window screenshot"),
    Key([MOD, SHIFT], "Print", lazy.spawn(f"maim -b 3 -s | xclip -sel c -t image/png && notify-send -i screengrab --hint=int:transient:1 -t {NOTIF_DURATION} 'screenshot (selection)' 'copied to clipboard'", shell=True), desc="Take screenshot of selection"),

    Key([MOD, SHIFT], "x",      lazy.spawn("xkill"), desc="Kill window"),
    Key([MOD, ALT],   "x",      lazy.spawn("xpick"), desc="Pick color"),
    Key([MOD, CTRL],  "x",      lazy.spawn(in_float_terminal("zsh -c 'xprop -id $(xdotool getwindowfocus) | less'"), shell=True), desc="Print window properties"),

    Key([MOD], "v",    lazy.spawn("clipmenu"), desc="Launch clipmenu"),
    Key([],    "Menu", lazy.spawn("clipmenu"), desc="Launch clipmenu"),
    Key([MOD], "Menu", lazy.spawn("eval '$(xclip -sel c -o)'"), desc="Run command in clipboard"),

    Key([MOD, SHIFT],      "space", lazy.spawn("notify-send 'Keyboard Layout' 'Toggle' && kblang -t", shell=True), desc="Toggle keyboard layout"),
    Key([MOD, ALT, SHIFT], "space", lazy.spawn(f"kblang -fn {DMENU_FONT}", shell=True), desc="Open keyboard layout selector"),

    Key([], "XF86Search", lazy.spawn("google-search"), desc="Launch google search"),

    Key([MOD], "Tab", lazy.spawn("rofi -show window -modi window"), desc="Launch window selector"),

    # TODO launch shell for qtile
    #bindsym $mod+Ctrl+Shift+semicolon exec --no-startup-id i3shell

    Key([MOD],        "F12", lazy.spawn("xdotool keyup Shift_L Shift_R Control_L Control_R Alt_L Alt_R Super_L Super_R Hyper_L Hyper_R Caps_Lock 204 205 206 207"), desc="Release all keys"),
    Key([MOD, SHIFT], "F12", lazy.spawn("autorandr --change && nitrogen --restore", shell=True), lazy.spawn(notification("reloaded config", "autorandr")), desc="Change monitor layout and reload wallpaper"),

    Key([MOD],        "Home",  lazy.spawn("desk stand",  shell=True), desc="Move desk to standing position"),
    Key([MOD],        "End",   lazy.spawn("desk sit",    shell=True), desc="Move desk to sitting position"),
    Key([MOD, ALT],   "Home",  lazy.spawn("desk up   7", shell=True), desc="Move desk up"),
    Key([MOD, ALT],   "End",   lazy.spawn("desk down 7", shell=True), desc="Move desk down"),

    KeyChord([MOD], "o", [
        Key([], "t", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t term"),      desc="(t)erminal"),
        Key([], "v", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t vscode"),    desc="(v)scode"),
        Key([], "n", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t vim"),       desc="(n)vim"),
        Key([], "i", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t idea"),      desc="(i)dea"),
        Key([], "c", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t clion"),     desc="(c)lion"),
        Key([], "g", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t goland"),    desc="(g)oland"),
        Key([], "p", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t pycharm"),   desc="(p)ycharm"),
        Key([], "w", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t webstorm"),  desc="(w)ebstorm"),
        Key([], "s", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t studio"),    desc="(s)tudio"),
        Key([], "r", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t rider"),     desc="(r)ider"),
        Key([], "j", lazy.spawn(f"codeopen -m {CODEOPEN_MENU} -t jetbrains"), desc="(j)etbrains-toolbox"),
    ], name="codeopen"),

    KeyChord([MOD, SHIFT], "o", [
        Key([], "t", lazy.spawn(TERMINAL),            desc="(t)erminal"),
        Key([], "v", lazy.spawn("vscodium"),          desc="(v)scode"),
        Key([], "n", lazy.spawn("vim"),               desc="(n)vim"),
        Key([], "i", lazy.spawn("idea"),              desc="(i)dea"),
        Key([], "c", lazy.spawn("clion"),             desc="(c)lion"),
        Key([], "g", lazy.spawn("goland"),            desc="(g)oland"),
        Key([], "p", lazy.spawn("pycharm"),           desc="(p)ycharm"),
        Key([], "w", lazy.spawn("webstorm"),          desc="(w)ebstorm"),
        Key([], "s", lazy.spawn("studio"),            desc="(s)tudio"),
        Key([], "r", lazy.spawn("rider"),             desc="(r)ider"),
        Key([], "j", lazy.spawn("jetbrains-toolbox"), desc="(j)etbrains-toolbox")
    ], name="launch"),

    Key([MOD, CTRL],      "Right",  lazy.next_screen(),                  desc="Move focus to next monitor"),
    Key([MOD, CTRL],      "Left",   lazy.prev_screen(),                  desc="Move focus to previous monitor"),
    Key([MOD, ALT, CTRL], "Right",  lazy.function(group_to_next_screen), desc="Move current group to next monitor"),
    Key([MOD, ALT, CTRL], "Left",   lazy.function(group_to_prev_screen), desc="Move current group to previous monitor"),

    Key([ALT], "Tab", lazy.screen.toggle_group(), desc="Toggle through layouts"),

    # sound&music
    # TODO add force_update calls for volume widgets
    Key([],                 "Xf86Tools",     scratchpad_toggle(PLAYER),                                                 desc="Toggle player"),
    Key([MOD],              "m",             scratchpad_toggle(PLAYER),                                                 desc="Toggle player"),
    Key([MOD, SHIFT],       "m",             scratchpad_toggle("cantata"),                                              desc="Toggle player"),
    Key([MOD],              "p",             scratchpad_toggle("pavucontrol"),                                          desc="Toggle PulseAudio Volume Control"),
    Key([MOD, CTRL],        "p",             lazy.spawn("padefault ma;" + update_widget_shell("outputvolumewidget"), shell=True), desc="Mute all outputs"),
    Key([MOD, ALT],         "p",             lazy.spawn("padefault mas" + update_widget_shell("inputvolumewidget"), shell=True),  desc="Mute all inputs"),
    Key([MOD, SHIFT],       "p",             lazy.spawn("padefault toggle"),                                            desc="Toggle default output device"),
    Key([MOD, CTRL, SHIFT], "p",             lazy.spawn("padefault toggle-focus"),                                      desc="Toggle output device of the focused window"),
    Key([MOD],              "period",        lazy.spawn("env BLOCK_BUTTON=1 ~/.local/bin/statusbar/music", shell=True), desc="Next media"),
    Key([MOD],              "slash",         lazy.spawn("env BLOCK_BUTTON=2 ~/.local/bin/statusbar/music", shell=True), desc="Play/pause active media"),
    Key([MOD],              "comma",         lazy.spawn("env BLOCK_BUTTON=3 ~/.local/bin/statusbar/music", shell=True), desc="Previous media"),
    Key([MOD, SHIFT],       "period",        lazy.spawn("env BLOCK_BUTTON=4 ~/.local/bin/statusbar/music", shell=True), desc="Volume up active media"),
    Key([MOD, SHIFT],       "comma",         lazy.spawn("env BLOCK_BUTTON=5 ~/.local/bin/statusbar/music", shell=True), desc="Volume down active media"),
    Key([MOD, CTRL, SHIFT], "period",        lazy.spawn("env BLOCK_BUTTON=6 ~/.local/bin/statusbar/music", shell=True), desc="Seek forward active media"),
    Key([MOD, CTRL, SHIFT], "comma",         lazy.spawn("env BLOCK_BUTTON=7 ~/.local/bin/statusbar/music", shell=True), desc="Seek backward active media"),
    Key([MOD, ALT],         "period",        lazy.spawn("padefault vol +5%"),                                           desc="Volume up default output device"),
    Key([MOD, ALT],         "slash",         lazy.spawn("padefault mute-all"),                                          desc="Mute all outputs"),
    Key([MOD, ALT],         "comma",         lazy.spawn("padefault vol -5%"),                                           desc="Volume down default output device"),
    Key([MOD, CTRL, ALT],   "period",        lazy.spawn("padefault volume-focus +5%"),                                  desc="Volume up of the focused window"),
    Key([MOD, CTRL, ALT],   "slash",         lazy.spawn("padefault volume-focus 100%"),                                 desc="Set volume of the focused window to 100%"),
    Key([MOD, CTRL, ALT],   "comma",         lazy.spawn("padefault volume-focus -5%"),                                  desc="Volume down of the focused window"),
    Key([],          "Xf86AudioPlay",        lazy.spawn("playerctl play-pause"),                                        desc="Toggle media play/pause"),
    Key([],          "Xf86AudioPause",       lazy.spawn("playerctl play-pause"),                                        desc="Toggle media play/pause"),
    Key([],          "Xf86AudioStop",        lazy.spawn("playerctl stop"),                                              desc="Stop media playback"),
    Key([],          "Xf86AudioNext",        lazy.spawn("playerctl next"),                                              desc="Next media"),
    Key([],          "Xf86AudioPrev",        lazy.spawn("playerctl previous"),                                          desc="Previous media"),
    Key([],          "XF86AudioRaiseVolume", lazy.spawn("padefault vol +1%"),                                           desc="Volume up default output device"),
    Key([],          "XF86AudioLowerVolume", lazy.spawn("padefault vol -1%"),                                           desc="Volume down default output device"),
    Key([],          "XF86AudioMute",        lazy.spawn("padefault mute-all"),                                          desc="Mute all outputs"),
    Key([],          "XF86AudioMicMute",     lazy.spawn("padefault mute-all-src"),                                      desc="Mute all inputs"),
    Key([SHIFT],     "XF86AudioRaiseVolume", lazy.spawn("env BLOCK_BUTTON=4 ~/.local/bin/statusbar/music", shell=True), desc="Volume up active media"),
    Key([SHIFT],     "XF86AudioLowerVolume", lazy.spawn("env BLOCK_BUTTON=5 ~/.local/bin/statusbar/music", shell=True), desc="Volume down active media"),
    Key([CTRL, ALT], "XF86AudioRaiseVolume", lazy.spawn("padefault volume-focus +1%"),                                  desc="Volume up of the focused window"),
    Key([CTRL, ALT], "XF86AudioLowerVolume", lazy.spawn("padefault volume-focus -1%"),                                  desc="Volume down of the focused window"),
    Key([ALT],       "XF86AudioRaiseVolume", lazy.spawn("padefault mic-volume +1%"),                                    desc="Volume up of the focused window"),
    Key([ALT],       "XF86AudioLowerVolume", lazy.spawn("padefault mic-volume -1%"),                                    desc="Volume down of the focused window"),

    Key([MOD], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
                                                                                                                                                                                                       # Layout Keybinds
    Key([MOD], "Left",              lazy.layout.left(),                       desc="Move focus to left"),
    Key([MOD], "Right",             lazy.layout.right(),                      desc="Move focus to right"),
    Key([MOD], "Down",              lazy.layout.down(),                       desc="Move focus down"),
    Key([MOD], "Up",                lazy.layout.up(),                         desc="Move focus up"),
    Key([MOD], "space",             lazy.layout.next(),                       desc="Move window focus to other window"),

    # Move windows between left/right columns or move up/down in current stack.
    Key([MOD, SHIFT], "Left",       lazy.layout.shuffle_left(),               desc="Move window to the left"),
    Key([MOD, SHIFT], "Right",      lazy.layout.shuffle_right(),              desc="Move window to the right"),
    Key([MOD, SHIFT], "Down",       lazy.layout.shuffle_down(),               desc="Move window down"),
    Key([MOD, SHIFT], "Up",         lazy.layout.shuffle_up(),                 desc="Move window up"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([MOD, ALT], "Left",         lazy.layout.grow_left(),                  desc="Grow window to the left"),
    Key([MOD, ALT], "Right",        lazy.layout.grow_right(),                 desc="Grow window to the right"),
    Key([MOD, ALT], "Down",         lazy.layout.grow_down(),                  desc="Grow window down"),
    Key([MOD, ALT], "Up",           lazy.layout.grow_up(),                    desc="Grow window up"),

    Key([MOD], "equal",      lazy.layout.grow_main(),                  desc="Grow main"),
    Key([MOD], "minus",      lazy.layout.shrink_main(),                desc="Shrink main"),
    Key([MOD], "space",      lazy.layout.swap_main(),                  desc="Swap main"),
    Key([MOD], "f",          lazy.window.toggle_fullscreen(),          desc="Toggle fullscreen"),
    Key([MOD], "g",          lazy.window.toggle_maximize(),            desc="Toggle maximize"),
    Key([MOD, SHIFT], "f",   lazy.layout.maximize(),                   desc="Maximize"),
    Key([MOD, SHIFT], "g",   lazy.layout.reset(),                      desc="Reset layout"),
    Key([MOD, SHIFT], "t",   lazy.next_layout(),                       desc="Toggle between layouts"),

    # Power options
    KeyChord([MOD], "0", [
        Key([SHIFT], "s",           lazy.spawn('i3exit shutdown'),         desc='(Shift + s)hutdown'),
        Key([], "r",                lazy.spawn('i3exit reboot'),           desc='(r)eboot'),
        Key([], "s",                lazy.spawn('i3exit suspend'),          desc='(s)uspend'),
        Key([], "h",                lazy.spawn('i3exit hibernate'),        desc='(h)ibernate'),
        Key([], "e",                lazy.spawn('i3exit logout'),           desc='(e)xit'),
        Key([], "l",                lazy.spawn('i3exit lock'),             desc='(l)ock'),
        Key([], "u",                lazy.spawn('i3exit switch_user'),      desc='switch (u)ser'),
    ], name='power'),

    Key([MOD], "F5", lazy.spawn("pgrep picom && killall picom || picom -b", shell=True), desc="Toggle picom"),

    # TODO keychord for changing layouts

    Key([MOD],        "s", lazy.spawn('qtile cmd-obj -o cmd -f switchgroup'), desc='Launch prompt to switch to a group'),
    Key([MOD, SHIFT], "s", lazy.spawn('qtile cmd-obj -o cmd -f togroup'),     desc='Launch prompt to move focused window to a group'),
    Key([MOD, CTRL],  "s", lazy.spawn('qtile cmd-obj -o cmd -f togroup'),     desc='Launch prompt to move focused window to a group'),
]
# @formatter:on


#   ____
#  / ___|_ __ ___  _   _ _ __  ___
# | |  _| '__/ _ \| | | | '_ \/ __|
# | |_| | | | (_) | |_| | |_) \__ \
#  \____|_|  \___/ \__,_| .__/|___/
#                       |_|
groups = [
    Group('1', layout="monadtall"),
    Group('2', layout="monadtall"),
    Group('3', layout="monadtall"),
    Group('4', layout="monadtall"),
    Group('5', layout="monadtall"),
    Group('6', layout="monadtall"),
    Group('7', layout="monadtall"),
    Group('8', layout="monadtall"),
    Group('9', layout="columns", matches=[
        Match(wm_class="telegram-desktop"),
        Match(wm_class="TelegramDesktop"),
        Match(wm_class="discord"),
        Match(wm_class="whatsapp-for-linux"),
        Match(wm_class="Microsoft Teams - Preview"),
        Match(wm_class="WhatsApp"),
        Match(wm_class="viber"),
    ]),
]

for i in groups:
    # @formatter:off
    keys.extend([
        Key([MOD],        i.name, lazy.function(focus_group_by_name(i.name)),   desc="Switch to group {}".format(i.name)),
        Key([MOD, CTRL],  i.name, lazy.window.togroup(i.name),                 desc="move focused window to group {}".format(i.name)),
        Key([MOD, SHIFT], i.name, lazy.window.togroup(i.name),
            lazy.function(focus_group_by_name(i.name)),                         desc="move focused window and screen to group {}".format(i.name)),
    ])
    # @formatter:on

# Append ScratchPad to groups list. Default ScratchPad.
groups.append(
    ScratchPad(SCRATCHPAD, [
        DropDown(TERMINAL, TERMINAL, **center(0.6, 0.6),
                 on_focus_lost_hide=False),
        DropDown(PLAYER, PLAYER, **center(0.6, 0.6)),
        DropDown("cantata", "cantata", **center(0.6, 0.6)),
        DropDown("calendar", in_float_terminal(CALENDAR), **center(0.6, 0.6),
                 on_focus_lost_hide=False),
        DropDown("pavucontrol", "pavucontrol", **center(0.4, 0.6)),
        DropDown("lutris", "lutris", **center(0.6, 0.6),
                 on_focus_lost_hide=False),
        DropDown("bitwarden-desktop", "bitwarden-desktop", **center(0.6, 0.6),
                 on_focus_lost_hide=False),
        DropDown(MAIL, MAIL, **center(0.8, 0.8), on_focus_lost_hide=False),
    ]),
)

#  _                            _
# | |    __ _ _   _  ___  _   _| |_ ___
# | |   / _` | | | |/ _ \| | | | __/ __|
# | |__| (_| | |_| | (_) | |_| | |_\__ \
# |_____\__,_|\__, |\___/ \__,_|\__|___/
#             |___/
default_layout_settings = dict(
    border_focus=color13,
    border_normal=color8,
    border_width=2,
    border_on_single=True,
    margin=GAPS_SIZE,
)

layouts = [
    layout.MonadTall(
        **default_layout_settings,
        new_client_position="top",
        ratio=0.75,
    ),
    layout.Columns(
        **default_layout_settings,
    ),
    layout.Max(
        **default_layout_settings,
    ),
]

# __        ___     _            _
# \ \      / (_) __| | __ _  ___| |_ ___
#  \ \ /\ / /| |/ _` |/ _` |/ _ \ __/ __|
#   \ V  V / | | (_| | (_| |  __/ |_\__ \
#    \_/\_/  |_|\__,_|\__, |\___|\__|___/
#                     |___/

widget_defaults = dict(
    font=FONT,
    fontsize=FONT_SIZE,
    padding=8
)

decoration_group = dict(
    decorations=[
        RectDecoration(colour=color3,
                       radius=12,
                       filled=True,
                       padding_y=4,
                       clip=True,
                       group=True)
    ],
    decoration_width=0,
    decoration_height=0,
)

extension_defaults = widget_defaults.copy()


#   ____ _   _ ____ _____ ___  __  __   __        _____ ____   ____ _____ _____  ____
#  / ___| | | / ___|_   _/ _ \|  \/  |  \ \      / /_ _|  _ \ / ___| ____|_   _|/ ___|
# | |   | | | \___ \ | || | | | |\/| |   \ \ /\ / / | || | | | |  _|  _|   | |  \___ \
# | |___| |_| |___) || || |_| | |  | |    \ V  V /  | || |_| | |_| | |___  | |   ___) |
#  \____|\___/|____/ |_| \___/|_|  |_|     \_/\_/  |___|____/ \____|_____| |_|  |____/


class VolumeWidget(qtile_extras_widget.GenPollText, ABC):
    """
    Abstract class that defines operations that a custom volume widget should implement.
    Volume widgets can control and display both input and output volumes.
    """
    defaults = [
        ("color_muted", color11),
        ("color_high", color12),
        ("color_medium", color13),
        ("color_low", color14),
    ]

    def __init__(self, **config):
        super().__init__(**config)
        self.add_defaults(VolumeWidget.defaults)
        self.add_callbacks({
            MOUSE_LEFT: self.cmd_open_cp,
            MOUSE_MIDDLE: self.cmd_toggle_mute,
            MOUSE_RIGHT: None,
            SCROLL_UP: self.cmd_increase_volume,
            SCROLL_DOWN: self.cmd_decrease_volume,
        })

    @abstractmethod
    def cmd_open_cp(self):
        """
        Open the volume control panel.
        """
        pass

    @abstractmethod
    def cmd_toggle_mute(self):
        """
        Toggle mute for all devices of this type.
        """
        pass

    @abstractmethod
    def cmd_increase_volume(self):
        """
        Increase volume of the default device.
        """
        pass

    @abstractmethod
    def cmd_decrease_volume(self):
        """
        Decrease volume of the default device.
        """
        pass

    @abstractmethod
    def cmd_is_muted(self) -> bool:
        """
        Check if all devices of this type are muted.
        """
        pass

    @abstractmethod
    def cmd_get_volume(self) -> int:
        """
        Gets the volume of the default device.
        """
        pass

    @abstractmethod
    def poll(self) -> str:
        """
        Polls the volume of the default device and returns a string representation.
        Defined in GenPollText.
        """
        pass


class OutputVolumeWidget(VolumeWidget):
    """
    Volume widget implementation that controls and displays output volumes.
    """

    defaults = [
        ("update_interval", 10),
        ("icon", ""),
        ("icon_muted", "婢"),
        ("format", "<span color='{color}'>{icon} {volume}%</span>"),
    ]

    def __init__(self, **config):
        super().__init__(**config)
        self.add_defaults(OutputVolumeWidget.defaults)

    def cmd_open_cp(self):
        qtile.cmd_spawn("pavucontrol -t 3")
        self.cmd_force_update()

    def cmd_toggle_mute(self):
        subprocess.call(["padefault", "ma"])
        self.cmd_force_update()

    def cmd_increase_volume(self):
        subprocess.call(["padefault", "vol", "+1%"])
        self.cmd_force_update()

    def cmd_decrease_volume(self):
        subprocess.call(["padefault", "vol", "-1%"])
        self.cmd_force_update()

    def cmd_is_muted(self):
        muted = int(subprocess.getoutput(
            "pactl list sinks | grep -B6 -c 'Mute: yes'"))
        sources = int(subprocess.getoutput(
            "pactl list sinks short | wc -l"))

        return muted == sources

    def cmd_get_volume(self):
        return int(subprocess.getoutput("getvol"))

    def poll(self):
        is_muted = self.cmd_is_muted()
        volume = 0
        # optimization to avoid calling get_volume if muted
        color = self.color_muted
        if not is_muted:
            volume = self.cmd_get_volume()

            if volume > 90:
                color = self.color_high
            elif volume > 66:
                color = self.color_medium
            elif volume > 33:
                color = self.color_low
            else:
                color = self.foreground

        variables = dict(
            icon=self.icon_muted if is_muted else self.icon,
            color=color,
            volume=volume,
        )

        return self.format.format(**variables)


class InputVolumeWidget(VolumeWidget):
    """
    Volume widget implementation that controls and displays input volumes (microphone).
    """

    defaults = [
        ("update_interval", 10),
        ("icon", ""),
        ("icon_muted", ""),
        ("format", "<span color='{color}'>{icon} {volume}%</span>"),
    ]

    def __init__(self, **config):
        super().__init__(**config)
        self.add_defaults(InputVolumeWidget.defaults)

    def cmd_open_cp(self):
        qtile.cmd_spawn("pavucontrol -t 4")
        self.cmd_force_update()

    def cmd_toggle_mute(self):
        subprocess.call(["padefault", "mas"])
        self.cmd_force_update()

    def cmd_increase_volume(self):
        subprocess.call(["padefault", "mic-volume", "+1%"])
        self.cmd_force_update()

    def cmd_decrease_volume(self):
        subprocess.call(["padefault", "mic-volume", "-1%"])
        self.cmd_force_update()

    def cmd_is_muted(self):
        muted = int(subprocess.getoutput(
            "pactl list sources | grep -B6 'Mute: yes' | grep 'Name:' | grep -vc 'monitor'"))
        sources = int(subprocess.getoutput(
            "pactl list sources short | grep -vc \"monitor\""))

        return muted == sources and muted > 0

    def cmd_get_volume(self):
        return int(subprocess.getoutput("getmicvol"))

    def poll(self):
        listening = subprocess.getoutput(
            "pactl list source-outputs | grep application.process.binary",
        ).strip()

        # hide if none are listening
        if listening == "":
            return ""

        is_muted = self.cmd_is_muted()
        volume = 0

        # optimization to avoid calling get_volume if muted
        color = self.color_muted
        if not is_muted:
            volume = self.cmd_get_volume()

            if volume > 90:
                color = self.color_high
            elif volume > 66:
                color = self.color_medium
            elif volume > 33:
                color = self.color_low
            else:
                color = self.foreground

        variables = dict(
            icon=self.icon_muted if is_muted else self.icon,
            color=color,
            volume=volume,
        )

        return self.format.format(**variables)


class Updates(qtile_extras_widget.CheckUpdates):
    """
    Customized CheckUpdates widget that allows displaying the number of updates
    in a notification. Also, allow setting the custom color depending on the
    number of pending updates.
    """

    defaults = [
        ("color_high", color11),
        ("color_medium", color12),
        ("color_low", color13),
        ("low_updates_threshold", 15),
        ("medium_updates_threshold", 40),
        ("high_updates_threshold", 75),
        ("notify_new_updates", lambda: None)
    ]

    def __init__(self, **config):
        super().__init__(**config)
        self.add_defaults(Updates.defaults)
        self.add_callbacks({
            MOUSE_LEFT: lambda: (
                self.cmd_force_update(), self.notify_new_updates()),
            MOUSE_MIDDLE: self.cmd_force_update,
        })
        self.num_updates = 0
        self.updates = ""

    def _check_updates(self):
        try:
            self.updates = self.call_process(self.cmd, shell=True)
        except subprocess.CalledProcessError:
            self.updates = ""

        num_updates = self.custom_command_modify(len(self.updates.splitlines()))

        if num_updates < 0:
            num_updates = 0

        if num_updates > self.num_updates:
            self.notify_new_updates()

        # store the number of updates for later use
        self.num_updates = num_updates

        if num_updates == 0:
            self.layout.colour = self.colour_no_updates
            return self.no_update_string

        if num_updates >= self.high_updates_threshold:
            self.layout.colour = self.color_high
        elif num_updates >= self.medium_updates_threshold:
            self.layout.colour = self.color_medium
        elif num_updates >= self.low_updates_threshold:
            self.layout.colour = self.color_low
        else:
            self.layout.colour = self.colour_have_updates

        return self.display_format.format(**{"updates": num_updates})


class NotificationWidgetBackend(ABC):
    """
    Abstract class for notification widget backend.
    Provides definitions for all necessary methods for a notification widget.
    """

    def __init__(self):
        if type(self) is NotificationWidgetBackend:
            raise TypeError("Can't instantiate abstract class")

    @abstractmethod
    def cmd_action(self):
        """
        Activate the notification action chooser.
        """
        pass

    @abstractmethod
    def cmd_pop(self):
        """
        Show the last notification.
        """
        pass

    @abstractmethod
    def cmd_close(self):
        """
        Close the last notification.
        """
        pass

    @abstractmethod
    def cmd_close_all(self):
        """
        Close all displayed notifications.
        """
        pass

    @abstractmethod
    def cmd_toggle_paused(self):
        """
        Toggle showing new notifications.
        """
        pass

    @abstractmethod
    def cmd_is_paused(self) -> bool:
        """
        Checks whether notifications are paused.
        """
        pass


class DunstNotificationWidgetBackend(NotificationWidgetBackend):
    """
    Notification widget backend implementation for dunst.
    """

    def cmd_is_paused(self) -> bool:
        return subprocess.check_output(["dunstctl", "is-paused"]).decode(
            "utf-8") == "false"

    def cmd_action(self):
        subprocess.call(["dunstctl", "context"])

    def cmd_pop(self):
        subprocess.call(["dunstctl", "history-pop"])

    def cmd_close(self):
        subprocess.call(["dunstctl", "close"])

    def cmd_close_all(self):
        subprocess.call(["dunstctl", "close-all"])

    def cmd_toggle_paused(self):
        subprocess.call(["dunstctl", "set-paused", "toggle"])


class NotificationWidget(qtile_extras_widget.GenPollText,
                         DunstNotificationWidgetBackend):
    defaults = [
        ("icon_active", ""),
        ("icon_inactive", ""),
        ("color_active", color4),
        ("color_inactive", color11),
        ("update_interval", 60, "Update interval."),
        ("format", "<span color='{color}'>{icon}</span>"),
        ("markup", True),
        ("is_active_cmd",
         lambda: subprocess.check_output(["dunstctl", "is-paused"]).decode(
             "utf-8").strip() == "false")
    ]

    def __init__(self, **config):
        super(qtile_extras_widget.GenPollText, self).__init__("", **config)
        self.add_defaults(NotificationWidget.defaults)
        self.add_callbacks({
            MOUSE_LEFT: self.cmd_pop,
            MOUSE_MIDDLE: self.cmd_toggle_paused,
            MOUSE_RIGHT: self.cmd_close_all,
            SCROLL_UP: self.cmd_close,
            SCROLL_DOWN: self.cmd_pop,
        })

    def cmd_toggle_paused(self):
        super().cmd_toggle_paused()
        self.cmd_force_update()

    def poll(self):
        active = self.is_active_cmd()

        variables = dict(
            icon=self.icon_active if active else self.icon_inactive,
            color=self.color_active if active else self.color_inactive,
        )

        return self.format.format(**variables)


class Clock(qtile_extras_widget.Clock):
    """
    Customized clock widget that allows hovering the widget to display the
    different format, eg. date.
    """

    def __init__(self, hover_format="%A, %B %d - %T", **config):
        super().__init__(**config)
        self.add_defaults(qtile_extras_widget.Clock.defaults)
        self.hover_format = hover_format
        self.default_format = self.format
        self.add_callbacks({
            MOUSE_LEFT: lambda: qtile.cmd_spawn(in_float_terminal(CALENDAR)),
            MOUSE_MIDDLE: self.toggle_format,
        })

    def toggle_format(self):
        fmt = self.default_format
        self.default_format = self.hover_format
        self.hover_format = fmt

    def mouse_enter(self, x, y):
        self.format = self.hover_format
        self.tick()

    def mouse_leave(self, x, y):
        self.format = self.default_format
        self.tick()


class DescriptiveChord(qtile_extras_widget.Chord):
    """
    Customized chord widget that displays the concatenated descriptions of all
    chorded keys. This presents the user with more information about the chord
    and which keys are available. Inspired by i3 mode command.
    """

    def __init__(self, **config):
        super().__init__(**config)
        self.add_defaults(qtile_extras_widget.Chord.defaults)

    def _setup_hooks(self):
        def hook_enter_chord(chord_name):
            if chord_name is True:
                self.text = ""
                self.reset_colours()
                return

            chord = None
            for _, keymap in qtile.keys_map.items():
                if isinstance(keymap, KeyChord) and keymap.name == chord_name:
                    chord = keymap
                    break

            if chord is not None:
                self.text = ", ".join(
                    filter(
                        lambda x: x != "",
                        map(
                            lambda x: x.desc,
                            chord.submappings)))

            if self.text == "":
                self.text = self.name_transform(chord_name)

            if chord_name in self.chords_colors:
                (self.background, self.foreground) = self.chords_colors.get(
                    chord_name)
            else:
                self.reset_colours()

            self.bar.draw()

        hook.subscribe.enter_chord(hook_enter_chord)
        hook.subscribe.leave_chord(self.clear)


class CpuWidget(qtile_extras_widget.CPU):
    """
    Customized CPU widget that displays the CPU usage with colored text.
    """

    defaults = [
        ("format",
         "<span size='large'>{icon}</span><span color='{color}'>{load_percent}%</span>"),
        ("color_low", color13),
        ("color_medium", color12),
        ("color_high", color11),
        ("update_interval", 2),
        ("foreground", foreground),
        ("markup", True),
        ("icon", ""),
        ("mouse_callbacks", {
            MOUSE_LEFT: lambda: qtile.cmd_spawn(
                notification("$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)",
                             title="Qtile - CpuWidget", icon="cpu"),
                shell=True),
            MOUSE_RIGHT: lambda: qtile.cmd_spawn(in_float_terminal("htop"))
        }),
    ]

    def __init__(self, **config):
        super().__init__(**config)
        self.add_defaults(CpuWidget.defaults)
        self.drawer = None

    def poll(self):
        variables = dict()

        load_percent = round(psutil.cpu_percent(interval=self.update_interval),
                             1)

        if load_percent > 90:
            variables["color"] = self.color_high
        elif load_percent > 80:
            variables["color"] = self.color_medium
        elif load_percent > 50:
            variables["color"] = self.color_low
        else:
            variables["color"] = self.foreground

        # 5 = 3 digits + 1 decimal + 1 decimal point
        variables["load_percent"] = str(load_percent).rjust(5, ' ')
        variables["icon"] = self.icon

        return self.format.format(**variables)


class CgsWidget(qtile_extras_widget.GenPollText):
    """
    Widget that wraps around and displays the output of the `cgs` (https://github.com/7aske/rgs) command.
    """

    defaults = [
        ("update_interval", 60),
        ("shell", True),
        ("format", " {}"),
        ("cmd", "cgs | wc -l"),
    ]

    def __init__(self, *args, **config):
        super().__init__(*args, **config)
        self.add_defaults(CgsWidget.defaults)
        self.add_callbacks({
            MOUSE_LEFT: lambda: qtile.cmd_spawn(
                notification("$(cgs)", title="Qtile - CgsWidget", icon="git"),
                shell=True),
        })
        self.count = 0

    def poll(self):
        self.count = int(
            subprocess.check_output(self.cmd, shell=self.shell).decode('utf-8')
        )

        # this hides the widget
        if self.count == 0:
            return ""

        return self.format.format(str(self.count))


NOTIFICATION_WIDGET = NotificationWidget(**decoration_group, fontsize=20)


def widget_icon(icon: str):
    return qtile_extras_widget.TextBox(
        **decoration_group,
        font='Fira Code',
        fontsize=16,
        text=icon,
        foreground=foreground,
    )


KEYBOARD_LAYOUT_ICON = widget_icon('')
KEYBOARD_LAYOUT_WIDGET = qtile_extras_widget.KeyboardLayout(
    **decoration_group,
    foreground=foreground,
    configured_keyboards=['us', 'rs latin', 'rs']
)

RAM_MEMORY_WIDGET_ICON = widget_icon('')
RAM_MEMORY_WIDGET = qtile_extras_widget.Memory(
    **decoration_group,
    foreground=foreground,
    measure_mem='G',
    format='{MemUsed:.0f}{mm}/{MemTotal:.0f}{mm}',
    mouse_callbacks={
        MOUSE_LEFT: lambda: qtile.cmd_spawn(
            notification("$(smem -Hkar | head)",
                         title="Qtile - MemoryWidget",
                         icon="device_mem"), shell=True),
        MOUSE_RIGHT: lambda: qtile.cmd_spawn(in_float_terminal("htop"))},
)

CHECK_UPDATES_WIDGET = Updates(
    **decoration_group,
    update_interval=1800,
    distro="Arch_checkupdates",
    display_format=" {updates}",
    colour_have_updates=foreground,
    colour_no_updates=background,
    notify_new_updates=lambda: qtile.cmd_spawn(
        notification("$(checkupdates | column -t)",
                     title="Qtile - UpdatesWidget",
                     icon="package", priority="low"), shell=True),
    mouse_callbacks={
        MOUSE_RIGHT: lambda: qtile.cmd_spawn(in_terminal("yay -Syu"))},
)

MIC_VOLUME_WIDGET = InputVolumeWidget(
    **decoration_group,
    foreground=foreground,
)

VOLUME_WIDGET = OutputVolumeWidget(
    **decoration_group,
    foreground=foreground,
)

DISK_FREE_WIDGETS = list(map(lambda part: qtile_extras_widget.DF(
    **decoration_group,
    foreground=foreground,
    warn_color=color11,
    partition=part.mountpoint,
    format='{p} {f}GB',
    warn_space=10,
    mouse_callbacks={
        MOUSE_LEFT: lambda: qtile.cmd_spawn(f"{FILE} {part.mountpoint}"),
    },
), psutil.disk_partitions()))

SYSTEM_CLOCK_WIDGET = Clock(
    **decoration_group,
    format="%T",
    foreground=foreground,
)

CPU_SENSOR_NAME = 'coretemp-isa-0000'
hostname = platform.node()
if hostname == 'mariner':
    CPU_SENSOR_NAME = 'Tctl'

CPU_THERMAL_SENSOR_WIDGET = qtile_extras_widget.ThermalSensor(
    **decoration_group,
    foreground=foreground,
    foreground_alert=color11,
    update_interval=2,
    threshold=60,
    fmt='{}',
    tag_sensor=CPU_SENSOR_NAME,
)

MUSIC_WIDGET_ICON = widget_icon('ﱘ')
MUSIC_WIDGET = qtile_extras_widget.Mpris2(
    **decoration_group,
    foreground=foreground,
    width=200,
    display_metadata=['xesam:title', 'xesam:artist'],
    paused_text='',
    stopped_text='',
    scroll_interval=0.025,
    no_metadata_text='-',
    scroll_delay=3,
    mouse_callbacks={
        MOUSE_LEFT: lambda: qtile.cmd_spawn(
            "env BLOCK_BUTTON=1 ~/.local/bin/statusbar/music", shell=True),
        MOUSE_MIDDLE: lambda: qtile.cmd_spawn(
            "env BLOCK_BUTTON=2 ~/.local/bin/statusbar/music", shell=True),
        MOUSE_RIGHT: lambda: qtile.cmd_spawn(
            "env BLOCK_BUTTON=3 ~/.local/bin/statusbar/music", shell=True),
        SCROLL_UP: lambda: qtile.cmd_spawn(
            "env BLOCK_BUTTON=4 ~/.local/bin/statusbar/music", shell=True),
        SCROLL_DOWN: lambda: qtile.cmd_spawn(
            "env BLOCK_BUTTON=5 ~/.local/bin/statusbar/music", shell=True),
    })

WEATHER_WIDGET = qtile_extras_widget.OpenWeather(
    **decoration_group,
    foreground=foreground,
    appid=os.getenv('OPENWEATHERMAP_API_KEY'),
    cityid=os.getenv('OPENWEATHERMAP_CITY_ID'),
    format='{icon} {temp:.0f}°{units_temperature}',
    mouse_callbacks={
        MOUSE_RIGHT: lambda: qtile.cmd_spawn(
            f"{BROWSER} https://openweathermap.org/city/{os.getenv('OPENWEATHERMAP_CITY_ID')}")
    },
)


def drawer(widgets_arr: list):
    return qtile_extras_widget.WidgetBox(
        **decoration_group,
        foreground=foreground,
        text_open='',
        text_closed='  ',
        widgets=widgets_arr,
    )


def spacer(width: Union[int, None] = None):
    if width is None:
        return widget.Spacer()
    return qtile_extras_widget.Spacer(
        length=width
    )


CGS_WIDGET = CgsWidget(**decoration_group)

CPU_WIDGET = CpuWidget(**decoration_group, width=70)

CHORD_WIDGET = DescriptiveChord(**decoration_group)

PROMPT_WIDGET = qtile_extras_widget.Prompt(
    **decoration_group,
)

NOTIFY_WIDGET = qtile_extras_widget.Notify(
    **decoration_group,
)


def layout_widget():
    return qtile_extras_widget.CurrentLayoutIcon(
        **decoration_group,
        scale=0.5,
        padding=2,
        foreground=foreground,
    )


def group_box_widget():
    return qtile_extras_widget.GroupBox(
        **decoration_group,
        hide_unused=True,
        highlight_method='block',
        block_highlight_text_color=background,
        urgent_border=color11,
        urgent_text=color11,
        background=transparent,
        inactive=background,
        active=color13,
        this_current_screen_border=color14,
        this_screen_border=color13,
        other_current_screen_border=color15,
        other_screen_border=color15,
        margin_x=-1,
        disable_drag=True,
    )


def tasklist_widget():
    return qtile_extras_widget.TaskList(
        **decoration_group,
        border=color14,
        foreground=background,
        borderwidth=1,
        margin_x=0,
        margin_y=0,
        highlight_method='block',
        urgent_border=color11,
        urgent_text=background,
        txt_floating=' ',
        txt_maximized=' ',
        txt_minimized=' ',
        icon_size=16,
        title_width_method="uniform",
    )


#  ____
# / ___|  ___ _ __ ___  ___ _ __  ___
# \___ \ / __| '__/ _ \/ _ \ '_ \/ __|
#  ___) | (__| | |  __/  __/ | | \__ \
# |____/ \___|_|  \___|\___|_| |_|___/
def screen_widgets(primary=False):
    widgets = [
        spacer(7),
        CHORD_WIDGET,
        spacer(3),
        layout_widget(),
        spacer(3),
        group_box_widget(),
        spacer(3),
        KEYBOARD_LAYOUT_ICON,
        KEYBOARD_LAYOUT_WIDGET,
        spacer(3),
        NOTIFICATION_WIDGET,
        spacer(3),
        CHECK_UPDATES_WIDGET,
        spacer(3),
        CGS_WIDGET,
        # spacer(3),
        # tasklist_widget(),
        spacer(3),
        PROMPT_WIDGET,
        spacer(),
        *DISK_FREE_WIDGETS,
        spacer(3),
        MUSIC_WIDGET_ICON,
        MUSIC_WIDGET,
        spacer(3),
        WEATHER_WIDGET,
        spacer(3),
        RAM_MEMORY_WIDGET_ICON,
        RAM_MEMORY_WIDGET,
        spacer(3),
        CPU_WIDGET,
        spacer(3),
        CPU_THERMAL_SENSOR_WIDGET,
        spacer(3),
        VOLUME_WIDGET,
        spacer(3),
        MIC_VOLUME_WIDGET,
        spacer(3),
        SYSTEM_CLOCK_WIDGET,
        spacer(7),
    ]
    if primary:
        widgets.extend([
            qtile_extras_widget.Systray(),
            spacer(7),
        ])
        return widgets
    return widgets


# We handle screens a bit more manually than usual, because we want to
# be able to set the refresh rate of each screen independently - to fix
# the issue when dragging and resizing a floating windows.
screens = []
if os.getenv("XDG_SESSION_TYPE") == "x11":
    from Xlib import display
    from Xlib.ext import randr

    # initialize Xlib and RandR extension
    d = display.Display(':0')
    info = d.screen(d.get_default_screen())
    res = randr.get_screen_resources(info.root)

    # get active modes for each screen
    active_modes = list(map(lambda inf: inf.mode,
                            filter(lambda c: c.mode,
                                   set(randr.get_crtc_info(info.root, crtc,
                                                           res.config_timestamp)
                                       for crtc in res.crtcs))))

    # calculate refresh rates for each mode since it's not available as
    # a property
    refresh_rates = {mode.id: (mode.dot_clock / (mode.h_total * mode.v_total))
                     for mode
                     in res.modes}

    # create a screen for each refresh rate. Refresh rates should correlate to
    # the number of screens
    for i, mode in enumerate(active_modes):
        screens.append(Screen(
            # get the refresh rade for each of the modes used by screens
            x11_drag_polling_rate=refresh_rates[mode],
            top=bar.Bar(
                # set only the first screen as primary
                screen_widgets(primary=i == 0),
                BAR_HEIGHT,
                background=transparent),
        ))
else:
    screens.extend([
        Screen(
            top=bar.Bar(
                screen_widgets(primary=True),
                BAR_HEIGHT,
                background=transparent),
        ),
        Screen(
            top=bar.Bar(
                screen_widgets(),
                BAR_HEIGHT,
                background=transparent),
        ),
        # Remove code block below for a two monitor setup
        Screen(
            top=bar.Bar(
                screen_widgets(),
                BAR_HEIGHT,
                background=transparent),
        ),
    ])

#  __  __
# |  \/  | ___  _   _ ___  ___
# | |\/| |/ _ \| | | / __|/ _ \
# | |  | | (_) | |_| \__ \  __/
# |_|  |_|\___/ \__,_|___/\___|

# Drag floating layouts.
mouse = [
    Drag([MOD], MOUSE_LEFT, lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([MOD], MOUSE_RIGHT, lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
]

#  _   _             _
# | | | | ___   ___ | | _____
# | |_| |/ _ \ / _ \| |/ / __|
# |  _  | (_) | (_) |   <\__ \
# |_| |_|\___/ \___/|_|\_\___/

floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="spotify"),
        Match(wm_class="floating"),
        Match(wm_class="kalendar"),
        Match(wm_class="pavucontrol"),
        Match(wm_class="lutris"),
        Match(wm_class="battle.net.exe"),
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ], **default_layout_settings)

dgroups_app_rules = [
    Rule(Match(title=['nested', 'gscreenshot'],
               wm_class=['Guake.py', 'Exe', 'Onboard', 'Florence',
                         'Plugin-container', 'Terminal', 'Gpaint',
                         'Kolourpaint', 'Wrapper', 'Gcr-prompter',
                         'Ghost', 'feh', 'Gnuplot', 'Pinta',
                         re.compile('Gnome-keyring-prompt.*?')],
               ),
         float=True, intrusive=True),

    # floating windows
    Rule(Match(wm_class=['Synfigstudio', 'Wine', 'Xephyr', 'postal2-bin'],
               title=[re.compile('[a-zA-Z]*? Steam'),
                      re.compile('Steam - [a-zA-Z]*?')]
               ),
         float=True),
    Rule(Match(wm_class=["St"]), float=False),
]

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None
bring_front_click = "floating_only"
auto_fullscreen = True
follow_mouse_focus = True
cursor_warp = True
reconfigure_screens = True
auto_minimize = False
wmname = "LG3D"
focus_on_window_activation = "focus"


#  ____  _             _
# / ___|| |_ __ _ _ __| |_ _   _ _ __
# \___ \| __/ _` | '__| __| | | | '_ \
#  ___) | || (_| | |  | |_| |_| | |_) |
# |____/ \__\__,_|_|   \__|\__,_| .__/
#                               |_|

@hook.subscribe.startup_once
def autostart():
    qtile.cmd_spawn(
        'pgrep pulseaudio || (while ! $(pulseaudio -k; pulseaudio -D); do; done)',
        shell=True)
    qtile.cmd_spawn('/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1',
                    shell=True)
    qtile.cmd_spawn('/usr/lib/geoclue-2.0/demos/agent', shell=True)
    qtile.cmd_spawn('nm-applet', shell=True)
    qtile.cmd_spawn('birdtray', shell=True)
    qtile.cmd_spawn('xmodmap ~/.Xmodmap', shell=True)
    qtile.cmd_spawn('pgrep udiskie || udiskie -s -f $file -a --appindicator',
                    shell=True)
    qtile.cmd_spawn('picom --experimental-backends', shell=True)
    qtile.cmd_spawn('xfce4-power-manager --daemon', shell=True)
    qtile.cmd_spawn('nitrogen --restore', shell=True)
    qtile.cmd_spawn('clipmenud', shell=True)
    qtile.cmd_spawn(
        'pgrep unclutter || unclutter --fork --timeout 5 --jitter 10 --ignore-scrolling',
        shell=True)
    qtile.cmd_spawn('xset r rate 195 55', shell=True)
    qtile.cmd_spawn('dunst_reload', shell=True)


@hook.subscribe.startup
def on_startup():
    qtile.cmd_spawn("xmodmap ~/.Xmodmap", shell=True)
