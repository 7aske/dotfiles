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

SYSTEMD_OUTDIR   := $(HOME)/.config/systemd/user
PACMAN_HOOKS_SRC := etc/pacman.d/hooks
PACMAN_HOOKS_DST := /etc/pacman.d/hooks

LOCALSEND_HOOKS_SRC := src/localsend/hooks
LOCALSEND_HOOKS_DST := $(HOME)/.config/localsend/hooks


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

scripts-uninstall: localsend-hooks-uninstall
	@set -- $(SCRIPT_PAIRS); \
	while [ $$# -gt 0 ]; do \
		$(RUN) ./uninstall.sh $$1 $$2; \
		shift 2; \
	done

.PHONY: localsend-hooks localsend-hooks-uninstall
localsend-hooks:
	@mkdir -p "$(LOCALSEND_HOOKS_DST)"
	@for f in $(LOCALSEND_HOOKS_SRC)/*; do \
		[ -f "$$f" ] || continue; \
		$(RUN) cp -v "$$f" "$(LOCALSEND_HOOKS_DST)/$$(basename "$$f")"; \
		$(RUN) chmod u+x "$(LOCALSEND_HOOKS_DST)/$$(basename "$$f")"; \
	done

localsend-hooks-uninstall:
	@for f in $(LOCALSEND_HOOKS_SRC)/*; do \
		[ -f "$$f" ] || continue; \
		h="$(LOCALSEND_HOOKS_DST)/$$(basename "$$f")"; \
		[ -f "$$h" ] && $(RUN) rm -v "$$h"; \
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
	$(RUN) ./util/mklink.sh $@


# ----------------------------
# Dotfiles (special cases)
# ----------------------------

tmux:
	$(RUN) ./util/mklink.sh tmux
	$(RUN) ln -sf "${HOME}/.config/tmux/.tmux.conf" "${HOME}/.tmux.conf"

vscode:
	$(RUN) mkdir -p "${HOME}/.config/VSCodium/User"
	$(RUN) ./util/mklink.sh "VSCodium/User/settings.json"
	$(RUN) ./util/mklink.sh "VSCodium/User/keybindings.json"
	$(RUN) mkdir -p "${HOME}/.config/Code/User"
	$(RUN) ./util/mklink.sh "Code/User/settings.json"
	$(RUN) ./util/mklink.sh "Code/User/keybindings.json"
	$(RUN) ./util/mklink.sh "Code/User/init.vim"

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
	$(RUN) ./util/mklink.sh zsh
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
	$(RUN) ./util/mksource.sh .$@


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

install: scripts-install localsend-hooks dotfiles-install completions-install check-deps

# check-deps.sh dispatches to .deps/check-arch-deps.sh or .deps/check-apt-deps.sh via /etc/os-release

.PHONY: check-deps check-arch-deps install-deps

check-deps:
	@DRYRUN=$(DRYRUN) ./check-deps.sh --non-interactive

check-arch-deps: check-deps

install-deps:
	@DRYRUN=$(DRYRUN) ./check-deps.sh --install

completions-install: \
	$(COMPLETIONS)

dotfiles-install: \
	$(DOTFILES) \
	tmux vscode zsh \
	$(SOURCES) \
	xmodmap ideavim imwheel

add:
	echo '#!/usr/bin/env sh' > $(SRC_DIR)/$(s).sh
	chmod +x $(SRC_DIR)/$(s).sh

.ONESHELL:
add-comp-zsh:
	cat <<EOF > $(SRC_DIR)/zsh-completions/_$(s)
	#compdef $(s) 
	_arguments "1[arg]"
	EOF
	chmod +x $(SRC_DIR)/zsh-completions/_$(s)
