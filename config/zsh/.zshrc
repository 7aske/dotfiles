#!/usr/bin/env zsh

typeset -g HISTFILE=~/.cache/zsh/history
typeset -g ADOTDIR=~/.config/antigen
typeset -g AWS_REGION_FILE="$HOME/.aws_region"
typeset -g AWS_PROFILE_FILE="$HOME/.aws_profile"
typeset -g AWS_CONFIG_FILE="$HOME/.aws/config"

setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt inc_append_history

is_console_tty() {
  [[ $(tty) == /dev/tty[1-9] ]]
}
cursor_beam()  { echo -ne '\e[6 q' }
cursor_block() { echo -ne '\e[2 q' }

[[ -r $AWS_PROFILE_FILE ]] && source $AWS_PROFILE_FILE
[[ -r $AWS_REGION_FILE  ]] && source $AWS_REGION_FILE
[[ -r ~/.config/zsh/antigen.zsh ]] && source ~/.config/zsh/antigen.zsh

antigen use oh-my-zsh

antigen bundle ael-code/zsh-colored-man-pages
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

antigen bundle argocd
antigen bundle aws
antigen bundle colored-man-pages
antigen bundle command-not-found
antigen bundle direnv
antigen bundle docker
antigen bundle docker-compose
antigen bundle emoji
antigen bundle fd
antigen bundle gitignore
antigen bundle gradle
antigen bundle helm
antigen bundle history-substring-search
antigen bundle kubectl
antigen bundle kubectx
antigen bundle minikube
antigen bundle mvn
antigen bundle npm
antigen bundle pip
antigen bundle rust
antigen bundle virtualenv
antigen bundle MichaelAquilina/zsh-you-should-use
if [ -x "$(command -v notify-send 2>/dev/null)" ]; then
	antigen bundle MichaelAquilina/zsh-auto-notify
fi

if is_console_tty; then
  antigen theme risto
else
  [[ -r ~/.config/zsh/agnoster-custom.zsh-theme ]] && source ~/.config/zsh/agnoster-custom.zsh-theme
fi

antigen apply

export AUTO_NOTIFY_THRESHOLD=20

[ -e ~/.config/rc ] && source ~/.config/rc

setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.

# Basic auto/tab complete:
setopt correct

# --- Completion paths ---
fpath=(~/.zsh/completions $fpath)

# --- Init completion system ---
autoload -Uz compinit
compinit

# --- Completion behavior ---
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:descriptions' format '%F{magenta}-- %d --%f'

setopt completealiases
setopt globdots

COMPLETION_WAITING_DOTS=true

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect h vi-backward-char
bindkey -M menuselect j vi-down-line-or-history
bindkey -M menuselect k vi-up-line-or-history
bindkey -M menuselect l vi-forward-char
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey -M viins '^[[A' history-substring-search-up
bindkey -M viins '^[[B' history-substring-search-down

# Change cursor shape for different vi modes.
zle-keymap-select() {
  case $KEYMAP in
    vicmd) cursor_block ;;
    *)     cursor_beam ;;
  esac
}
zle -N zle-keymap-select

function zle-line-init() {
  zle -K viins
  cursor_beam
}
zle -N zle-line-init

# change dir using FZF
fzf-cd() {
  local file

  file=$(fzf \
    --preview 'bat --color=always {} 2>/dev/null || ls -la --color=always {}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    --bind 'ctrl-e:execute(vim {})'
  ) || return

  cd -- "${file:h}"
}
bindkey -s '^f' 'fzf-cd\n'
# script from dotfiles
bindkey -s '^[f' 'fzf-rg\n'

bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -s '^o' 'codeopen\n'
bindkey -s '^g' 'chgs\n'
bindkey -s '^v' 'vicfg -H -c -s\n'
bindkey -s '^p' 'git pull\n'
bindkey -s '^u' 'git push\n'
bindkey -s '^s' 'git status\n'
bindkey -s '^y' 'yay\n'

# ctrl+space
bindkey '^@' autosuggest-accept
bindkey '^r' history-incremental-search-backward

alias dockerhost="export DOCKER_HOST=\$(docker context inspect \$(docker context show) | jq -r '.[0].Endpoints.docker.Host')"

# pidswallow
[ -n "$DISPLAY" ]  && command -v xdo >/dev/null 2>&1 && xdo id > /tmp/term-wid-"$$"
trap "( rm -f /tmp/term-wid-"$$" )" EXIT HUP

[ -e "$HOME/.zprofile" ] && source "$HOME/.zprofile"

function toggle-autocomplete {
    if [ -z "$ZSH_AUTOSUGGEST_HISTORY_IGNORE" ]; then
        export ZSH_AUTOSUGGEST_HISTORY_IGNORE=\*
    else
        unset ZSH_AUTOSUGGEST_HISTORY_IGNORE
    fi
}

function aws_profile() {
    local profile region

    # unset
    if [[ $1 == -u ]]; then
        unset AWS_PROFILE
        rm -f "$AWS_PROFILE_FILE"
        aws_region -u
        return
    fi

    # profile provided or selected
    if [[ -n $1 ]]; then
        profile=$1
    else
        profile=$(
            sed -n 's/^\[profile \(.*\)\]/\1/p' "$AWS_CONFIG_FILE" |
            fzf --header="Select AWS Profile"
        )
    fi

    [[ -z $profile ]] && return

    export AWS_PROFILE=$profile
    echo "export AWS_PROFILE=$profile" > "$AWS_PROFILE_FILE"

    region=$(aws configure get region)
    aws_region "$region"
}

function aws_region() {
    local region

    # unset
    if [[ $1 == -u ]]; then
        unset AWS_DEFAULT_REGION AWS_REGION
        rm -f "$AWS_REGION_FILE"
        return
    fi

    # region provided or selected
    if [[ -n $1 ]]; then
        region=$1
    else
        region=$(
            awk '/region/ {print $3}' "$AWS_CONFIG_FILE" |
            sort -u |
            fzf --header="Select AWS Region"
        )
    fi

    [[ -z $region ]] && return

    export AWS_DEFAULT_REGION=$region
    export AWS_REGION=$region
    echo "export AWS_DEFAULT_REGION=$region" > "$AWS_REGION_FILE"
}
