OUTDIR=~/.local/bin
INDIR=src
STATUS_OUTDIR=~/.local/bin/statusbar
STATUS_INDIR=src/statusbar
SYSTEMD_INDIR=src/systemd
SYSTEMD_OUTDIR=~/.config/systemd/user
PACMAN_HOOKS_INDIR=etc/pacman.d/hooks
PACMAN_HOOKS_OUTDIR=/etc/pacman.d/hooks

ifeq (uninstall,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif

default_recipe: scripts-install

.PHONY: install
install: scripts-install dotfiles-install

.PHONY: scripts-install
scripts-install:
	./install.sh $(INDIR) $(OUTDIR)
	./install.sh $(STATUS_INDIR) $(STATUS_OUTDIR)

.PHONY: scripts-uninstall
scripts-uninstall:
	./uninstall.sh $(INDIR) $(OUTDIR)
	./uninstall.sh $(STATUS_INDIR) $(STATUS_OUTDIR)

add:
	touch src/$(s).sh
	chmod u+x src/$(s).sh
	echo "#!/usr/bin/env bash" >> src/$(s).sh

systemd:
	cp $(SYSTEMD_INDIR)/* $(SYSTEMD_OUTDIR)/

pacman-hooks:
	for file in $(PACMAN_HOOKS_INDIR)/*; do \
		envsubst < $$file | sudo tee $(PACMAN_HOOKS_OUTDIR)/$$(basename $$file); \
	done

.PHONY: dotfiles-install
dotfiles-install: albert \
	bspwm \
	sxhkd \
	conky \
	colors.sh \
	dunst \
	i3 \
	i3blocks \
	i3status-rust \
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
	qtile \
	k9s

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

i3status-rust:
	./mklink i3status-rust

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

k9s:
	./mklink k9s
