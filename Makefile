# ----------------------------
# Config
# ----------------------------

DRYRUN ?= 0

ifeq ($(DRYRUN),1)
	RUN := echo
else
	RUN :=
endif

BIN_DIR          := ~/.local/bin
SRC_DIR          := src

STATUS_DIR       := statusbar
SYSTEMD_DIR      := systemd

SYSTEMD_OUTDIR   := ~/.config/systemd/user
PACMAN_HOOKS_SRC := etc/pacman.d/hooks
PACMAN_HOOKS_DST := /etc/pacman.d/hooks


# ----------------------------
# Uninstall arg passthrough
# ----------------------------

ifeq (uninstall,$(firstword $(MAKECMDGOALS)))
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)
endif

default: install

# ----------------------------
# Script install / uninstall
# ----------------------------

SCRIPT_PAIRS := \
	$(SRC_DIR) $(BIN_DIR) \
	$(SRC_DIR)/$(STATUS_DIR) $(BIN_DIR)/$(STATUS_DIR)

.PHONY: scripts-install scripts-uninstall

scripts-install:
	@set -- $(SCRIPT_PAIRS); \
	while [ $$# -gt 0 ]; do \
		$(RUN) ./install.sh $$1 $$2; \
		shift 2; \
	done

scripts-uninstall:
	@set -- $(SCRIPT_PAIRS); \
	while [ $$# -gt 0 ]; do \
		$(RUN) ./uninstall.sh $$1 $$2; \
		shift 2; \
	done

COMPLETIONS := rgs

.PHONY: $(COMPLETIONS)
$(COMPLETIONS):
	$(RUN) ./complete.sh $@

# ----------------------------
# Dotfiles (generic)
# ----------------------------

DOTFILES := \
	albert bspwm sxhkd conky colors.sh dunst i3 i3blocks \
	i3status-rust i3status kitty mpd nano neofetch newsboat \
	nvim ranger rofi sxiv wal xfce4 compton picom zathura \
	rc Xresources taskrc qtile k9s

.PHONY: $(DOTFILES)
$(DOTFILES):
	$(RUN) ./mklink $@


# ----------------------------
# Dotfiles (special cases)
# ----------------------------

tmux:
	$(RUN) ./mklink tmux
	$(RUN) ln -sf "${HOME}/.config/tmux/.tmux.conf" "${HOME}/.tmux.conf"

vscode:
	$(RUN) mkdir -p "${HOME}/.config/VSCodium/User"
	$(RUN) ./mklink "VSCodium/User/settings.json"
	$(RUN) ./mklink "VSCodium/User/keybindings.json"
	$(RUN) mkdir -p "${HOME}/.config/Code/User"
	$(RUN) ./mklink "Code/User/settings.json"
	$(RUN) ./mklink "Code/User/keybindings.json"
	$(RUN) ./mklink "Code/User/init.vim"

VSCODE_EXTENSIONS := arcticicestudio.nord-visual-studio-code \
	github.copilot \
	github.copilot-chat \
	ms-azuretools.vscode-containers \
	ms-vscode-remote.remote-containers \
	ms-vscode.makefile-tools \
	timonwong.shellcheck \
	vscodevim.vim
vscode-ext:
	@for ext in $(VSCODE_EXTENSIONS); do \
		$(RUN) /usr/bin/code --install-extension $$ext || $(RUN) /usr/bin/codium --install-extension $$ext; \
	done

zsh:
	$(RUN) ./mklink zsh
	$(RUN) mkdir -p "${HOME}/.cache/zsh"
	$(RUN) ln -sf "${HOME}/.config/zsh/.zshrc" "${HOME}/.zshrc"

xmodmap:
	$(RUN) ln -sf "$(PWD)/.Xmodmap" "${HOME}/.Xmodmap"

ideavim:
	$(RUN) ln -sf "$(PWD)/.ideavimrc" "${HOME}/.ideavimrc"

imwheel:
	$(RUN) ln -sf "$(PWD)/.imwheelrc" "${HOME}/.imwheelrc"


# ----------------------------
# Source-based dotfiles
# ----------------------------

SOURCES := profile xprofile bashrc

.PHONY: $(SOURCES)
$(SOURCES):
	$(RUN) ./mksource .$@


# ----------------------------
# systemd & pacman hooks
# ----------------------------

systemd:
	$(RUN) cp $(SYSTEMD_DIR)/* $(SYSTEMD_OUTDIR)/

pacman-hooks:
	@for f in $(PACMAN_HOOKS_SRC)/*; do \
		$(RUN) sh -c 'envsubst < "$$1" | sudo tee "$(PACMAN_HOOKS_DST)/$$(basename "$$1")"' _ $$f; \
	done


# ----------------------------
# Aggregate targets
# ----------------------------

.PHONY: default install dotfiles-install

install: scripts-install dotfiles-install completions-install

completions-install: \
	$(COMPLETIONS)

dotfiles-install: \
	$(DOTFILES) \
	tmux vscode zsh \
	$(SOURCES) \
	xmodmap ideavim imwheel
