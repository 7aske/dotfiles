#!/usr/bin/env bash

prog="$(basename $0 .sh)"
[ "$(basename $(pwd))" != "dotfiles" ] && echo "$prog: must be run in dotfiles repo root"

[ ! -e "$HOME/.config" ] && mkdir "$HOME/.config"

mklink () {
	if [ -e "$HOME/.config/$1" ] && [ ! -L "$HOME/.config/$1" ]; then
		mv "$HOME/.config/$1" "$HOME/.config/$1.bak"
	fi

	if [ ! -e "$HOME/.config/$1" ]; then
		ln -s "$(pwd)/.config/$1" "$HOME/.config/$1"
	fi
}

# albert
mklink albert

# bug.n

# conky
mklink conky

# dunst
mklink dunst

# i3
mklink i3

# i3blocks
mklink i3blocks

# i3status
mklink i3status

# kitty
mklink kitty

# Microsoft.WindowsTerminal

# neofetch
mklink neofetch

# nvim
mklink nvim

# rofi
mklink rofi

# sxiv
mklink sxiv

# tmux
mklink tmux
ln -s "$HOME/.config/tmux/.tmux.conf" "$HOME/.tmux.conf"

# VSCodium
mklink "VSCodium/User/settings.json"
mklink "VSCodium/User/keybindings.json"

# wal
mklink wal

# xfce4
mklink xfce4

# .profile

# .xprofile

# .Xresources
