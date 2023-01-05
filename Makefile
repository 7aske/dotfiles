ifeq (uninstall,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif


.PHONY: all
all: albert \
	bspwm \
	sxhkd \
	conky \
	colors.sh \
	dunst \
	i3 \
	i3blocks \
	i3status \
	kitty \
	mpd \
	nano \
	neofetch \
	newsboat \
	nvim \
	ranger \
	rofi \
	sxiv \
	tmux \
	vscode \
	wal \
	xfce4 \
	compton \
	picom \
	zsh \
	zathura \
	xmodmap \
	profile \
	xprofile \
	bashrc \
	rc \
	xresources \
	ideavim \
	imwheel \
	qtile

albert:
	./mklink albert

bspwm:
	./mklink bspwm

sxhkd:
	./mklink sxhkd

conky:
	./mklink conky

colors.sh:
	./mklink colors.sh

dunst:
	./mklink dunst

i3:
	./mklink i3

i3blocks:
	./mklink i3blocks

i3status:
	./mklink i3status

kitty:
	./mklink kitty

mpd:
	./mklink mpd

nano:
	./mklink nano

neofetch:
	./mklink neofetch

newsboat:
	./mklink newsboat

nvim:
	./mklink nvim

ranger:
	./mklink ranger

rofi:
	./mklink rofi

sxiv:
	./mklink sxiv

tmux:
	./mklink tmux
	ln -sf "${HOME}/.config/tmux/.tmux.conf" "${HOME}/.tmux.conf"

vscode:
	mkdir -p "${HOME}/.config/VSCodium/User/"
	./mklink "VSCodium/User/settings.json"
	./mklink "VSCodium/User/keybindings.json"

wal:
	./mklink wal

xfce4:
	./mklink xfce4

compton:
	./mklink compton
	./mklink picom

picom: compton

zsh:
	./mklink zsh
	mkdir -p ${HOME}/.cache/zsh
	ln -sf "${HOME}/.config/zsh/.zshrc" "${HOME}/.zshrc"

zathura:
	./mklink zathura

xmodmap:
	ln -sf "$(shell pwd)/.Xmodmap" "${HOME}/.Xmodmap"

profile:
	./mksource .profile

xprofile:
	./mksource .xprofile

bashrc:
	./mksource .bashrc

rc:
	./mklink rc

xresources:
	./mklink Xresources

ideavim:
	ln -sf "$(shell pwd)/.ideavimrc" "${HOME}/.ideavimrc"

imwheel:
	ln -sf "$(shell pwd)/.imwheelrc" "${HOME}/.imwheelrc"

task:
	./mklink task
	./mklink taskrc

qtile:
	./mklink qtile
