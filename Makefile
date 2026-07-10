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

# Cursor config dir (matches cursor-agent): CURSOR_CONFIG_DIR > $XDG_CONFIG_HOME/cursor > ~/.cursor
CURSOR_CONFIG_DIR_RESOLVED := $(shell \
	if [ -n "$$CURSOR_CONFIG_DIR" ]; then printf '%s' "$$CURSOR_CONFIG_DIR"; \
	elif [ -n "$$XDG_CONFIG_HOME" ]; then printf '%s/cursor' "$$XDG_CONFIG_HOME"; \
	else printf '%s/.cursor' "$$HOME"; fi)

AGENT_HOOKS_SRC := src/agent-hooks
AGENT_HOOKS_SHARE := $(HOME)/.local/share/agent-hooks
AGENT_HOOKS_CLAUDE_DST := $(HOME)/.claude/hooks
AGENT_HOOKS_CURSOR_DST := $(HOME)/.cursor/hooks
AGENT_HOOKS_CLAUDE_JSON_SRC := $(AGENT_HOOKS_SRC)/hooks-claude.json
AGENT_HOOKS_CURSOR_JSON_SRC := $(AGENT_HOOKS_SRC)/hooks-cursor.json
AGENT_HOOKS_CLAUDE_JSON_DST := $(HOME)/.claude/settings.json
AGENT_HOOKS_CURSOR_JSON_DST := $(HOME)/.cursor/hooks.json

AGENT_STATUSLINE_SRC := src/agent-statusline
AGENT_STATUSLINE_SHARE := $(HOME)/.local/share/agent-statusline
AGENT_STATUSLINE_CLAUDE_DST := $(HOME)/.claude/statusline
AGENT_STATUSLINE_CLAUDE_ADAPTER := $(AGENT_STATUSLINE_CLAUDE_DST)/statusline-command.sh
AGENT_STATUSLINE_CURSOR_ADAPTER := $(HOME)/.cursor/statusline.sh
AGENT_STATUSLINE_CLAUDE_JSON_SRC := $(AGENT_STATUSLINE_SRC)/statusline-claude.json
AGENT_STATUSLINE_CURSOR_JSON_SRC := $(AGENT_STATUSLINE_SRC)/statusline-cursor.json
AGENT_STATUSLINE_CLAUDE_JSON_DST := $(HOME)/.claude/settings.json
AGENT_STATUSLINE_CURSOR_JSON_DST := $(CURSOR_CONFIG_DIR_RESOLVED)/cli-config.json


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

scripts-uninstall: localsend-hooks-uninstall agent-hooks-uninstall agent-statusline-uninstall
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

.PHONY: agent-hooks agent-hooks-uninstall
agent-hooks:
	@mkdir -p "$(AGENT_HOOKS_SHARE)" "$(AGENT_HOOKS_CLAUDE_DST)" "$(AGENT_HOOKS_CURSOR_DST)"
	@for f in $(AGENT_HOOKS_SRC)/core/*.sh; do \
		[ -f "$$f" ] || continue; \
		$(RUN) cp -v "$$f" "$(AGENT_HOOKS_SHARE)/$$(basename "$$f")"; \
		$(RUN) chmod u+x "$(AGENT_HOOKS_SHARE)/$$(basename "$$f")"; \
	done
	@$(RUN) cp -v "$(AGENT_HOOKS_SRC)/adapters/claude-notification.sh" "$(AGENT_HOOKS_CLAUDE_DST)/notify-decision.sh"
	@$(RUN) chmod u+x "$(AGENT_HOOKS_CLAUDE_DST)/notify-decision.sh"
	@$(RUN) cp -v "$(AGENT_HOOKS_SRC)/adapters/cursor-pretooluse-ask.sh" "$(AGENT_HOOKS_CURSOR_DST)/notify-decision.sh"
	@$(RUN) chmod u+x "$(AGENT_HOOKS_CURSOR_DST)/notify-decision.sh"
	@$(RUN) cp -v "$(AGENT_HOOKS_SRC)/adapters/cursor-stop.sh" "$(AGENT_HOOKS_CURSOR_DST)/notify-agent-done.sh"
	@$(RUN) chmod u+x "$(AGENT_HOOKS_CURSOR_DST)/notify-agent-done.sh"
	@$(RUN) ./util/merge-hooks-json.sh claude "$(AGENT_HOOKS_CLAUDE_JSON_SRC)" "$(AGENT_HOOKS_CLAUDE_JSON_DST)"
	@$(RUN) ./util/merge-hooks-json.sh cursor "$(AGENT_HOOKS_CURSOR_JSON_SRC)" "$(AGENT_HOOKS_CURSOR_JSON_DST)"

agent-hooks-uninstall:
	@for f in $(AGENT_HOOKS_SRC)/core/*.sh; do \
		[ -f "$$f" ] || continue; \
		h="$(AGENT_HOOKS_SHARE)/$$(basename "$$f")"; \
		[ -f "$$h" ] && $(RUN) rm -v "$$h"; \
	done
	@for f in notify-decision.sh notify-agent-done.sh; do \
		[ -f "$(AGENT_HOOKS_CLAUDE_DST)/$$f" ] && $(RUN) rm -v "$(AGENT_HOOKS_CLAUDE_DST)/$$f"; \
		[ -f "$(AGENT_HOOKS_CURSOR_DST)/$$f" ] && $(RUN) rm -v "$(AGENT_HOOKS_CURSOR_DST)/$$f"; \
	done
	@$(RUN) ./util/merge-hooks-json.sh claude "$(AGENT_HOOKS_CLAUDE_JSON_SRC)" "$(AGENT_HOOKS_CLAUDE_JSON_DST)" --remove
	@$(RUN) ./util/merge-hooks-json.sh cursor "$(AGENT_HOOKS_CURSOR_JSON_SRC)" "$(AGENT_HOOKS_CURSOR_JSON_DST)" --remove
	@$(RUN) rmdir "$(AGENT_HOOKS_SHARE)" 2>/dev/null || true

.PHONY: agent-statusline agent-statusline-uninstall
agent-statusline:
	@mkdir -p "$(AGENT_STATUSLINE_SHARE)" "$(AGENT_STATUSLINE_CLAUDE_DST)"
	@for f in $(AGENT_STATUSLINE_SRC)/core/*.sh; do \
		[ -f "$$f" ] || continue; \
		$(RUN) cp -v "$$f" "$(AGENT_STATUSLINE_SHARE)/$$(basename "$$f")"; \
		$(RUN) chmod u+x "$(AGENT_STATUSLINE_SHARE)/$$(basename "$$f")"; \
	done
	@$(RUN) cp -v "$(AGENT_STATUSLINE_SRC)/adapters/claude.sh" "$(AGENT_STATUSLINE_CLAUDE_ADAPTER)"
	@$(RUN) chmod u+x "$(AGENT_STATUSLINE_CLAUDE_ADAPTER)"
	@$(RUN) cp -v "$(AGENT_STATUSLINE_SRC)/adapters/cursor.sh" "$(AGENT_STATUSLINE_CURSOR_ADAPTER)"
	@$(RUN) chmod u+x "$(AGENT_STATUSLINE_CURSOR_ADAPTER)"
	@$(RUN) ./util/merge-statusline-json.sh "$(AGENT_STATUSLINE_CLAUDE_JSON_SRC)" "$(AGENT_STATUSLINE_CLAUDE_JSON_DST)"
	@$(RUN) ./util/merge-statusline-json.sh "$(AGENT_STATUSLINE_CURSOR_JSON_SRC)" "$(AGENT_STATUSLINE_CURSOR_JSON_DST)"

agent-statusline-uninstall:
	@for f in $(AGENT_STATUSLINE_SRC)/core/*.sh; do \
		[ -f "$$f" ] || continue; \
		h="$(AGENT_STATUSLINE_SHARE)/$$(basename "$$f")"; \
		[ -f "$$h" ] && $(RUN) rm -v "$$h"; \
	done
	@[ -f "$(AGENT_STATUSLINE_CLAUDE_ADAPTER)" ] && $(RUN) rm -v "$(AGENT_STATUSLINE_CLAUDE_ADAPTER)"
	@[ -f "$(AGENT_STATUSLINE_CURSOR_ADAPTER)" ] && $(RUN) rm -v "$(AGENT_STATUSLINE_CURSOR_ADAPTER)"
	@$(RUN) ./util/merge-statusline-json.sh "$(AGENT_STATUSLINE_CLAUDE_JSON_SRC)" "$(AGENT_STATUSLINE_CLAUDE_JSON_DST)" --remove
	@$(RUN) ./util/merge-statusline-json.sh "$(AGENT_STATUSLINE_CURSOR_JSON_SRC)" "$(AGENT_STATUSLINE_CURSOR_JSON_DST)" --remove
	@$(RUN) rmdir "$(AGENT_STATUSLINE_SHARE)" "$(AGENT_STATUSLINE_CLAUDE_DST)" 2>/dev/null || true

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

install: scripts-install localsend-hooks agent-hooks agent-statusline dotfiles-install completions-install check-deps

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
