# vim:ft=zsh ts=2 sw=2 sts=2

#
# 7aske's adaptation of agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](https://iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# If using with "light" variant of the Solarized color schema, set
# SOLARIZED_THEME variable to "light". If you don't specify, we'll assume
# you're using the "dark" variant.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

autoload -U colors && colors	# Load colors
CURRENT_BG='NONE'

case ${SOLARIZED_THEME:-dark} in
    light) CURRENT_FG='white';;
    *)     CURRENT_FG='black';;
esac

export ZSH_THEME_AWS_PROFILE_PREFIX=" "
export ZSH_THEME_AWS_PROFILE_SUFFIX=""
export ZSH_THEME_AWS_REGION_PREFIX=""
export ZSH_THEME_AWS_REGION_SUFFIX=""
export SHOW_AWS_PROMPT=false

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old verson of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown
# Context: user@hostname (who am I and where am I)
prompt_context() {
	local background foreground prompt
	prompt="%n@%m"
	background=black
	foreground=default

	if [[ "$UID" == "0" ]]; then
		foreground=red
	fi

  if [[ -n "$SSH_CLIENT" ]]; then
		background=magenta
  fi

	prompt_segment $background $foreground $prompt
}

evil_git_num_untracked_files() {
  expr `git status --porcelain 2>/dev/null| grep "^??" | wc -l` 
}

evil_git_uncommited() {
	expr $(git status --porcelain 2>/dev/null| grep -E "^(M| M)" | wc -l)
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path uncommited

   if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]]; then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
		uncommited=$(evil_git_uncommited)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if (( $uncommited )); then
      prompt_segment yellow black
    else
      prompt_segment green $CURRENT_FG
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info
		precmd() { vcs_info }

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr "±${uncommited}"
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
		echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $CURRENT_FG '%1~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    #prompt_segment blue black "`basename $virtualenv_path`"
    prompt_segment blue black " `python --version | cut -d ' ' -f2`"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols job
	job=$(jobs -l | wc -l)

  symbols+="%{%F{red}%}%(?..%B%?%b)"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}󱐋"
  [[ $job -gt 0 ]] && symbols+="%{%F{cyan}%}$job  "
  [[ -n "$symbols" ]] && prompt_segment default default "$symbols%f"
}

prompt_docker() {
  local docker_host=$(docker context show 2>/dev/null)
  if [[ -n $docker_host ]] && [[ $docker_host != default ]]; then
    prompt_segment default green " $docker_host"
  fi
}

# Faster since it doesn't run kubectl
prompt_kubernetes() {
  local kube_config=${KUBECONFIG:-$HOME/.kube/config}
  if [[ ! -f $kube_config ]]; then
    return
  fi
  local color=blue

  local current_ctx=$(awk '$1 == "current-context:" {
    if ($2 ~ /^".*"$/) {
      print substr($2, 2, length($2) - 2) 
    } else {
      print $2 
    } 
  }' $kube_config  2>/dev/null)

  if [[ -z "$current_ctx" ]]; then
    return
  fi

  if [[ "$current_ctx" =~ ".*prod.*" ]]; then
    color=red
  fi

  prompt_segment default $color " ${kubectx_mapping[$current_ctx]:-${current_ctx:gs/%/%%}}"
}

prompt_kubectx() {
  (( $+commands[kubectl] )) || return
  local color=blue

  local current_ctx=$(kubectl config current-context 2> /dev/null)

  [[ -n "$current_ctx" ]] || return

  if [[ "$current_ctx" =~ ".*prod.*" ]]; then
    color=red
  fi

  prompt_segment default $color " ${kubectx_mapping[$current_ctx]:-${current_ctx:gs/%/%%}}"
}

prompt_aws() {
  local aws_profile="$AWS_PROFILE"
  local color=yellow
  
  if [[ "$aws_profile" =~ ".*prod.*" ]]; then
    color=red
  fi

  if [[ -n "$aws_profile" ]]; then
    prompt_segment default $color " $aws_profile"
  fi
}

prompt_aws2() {
  local aws_profile="$AWS_PROFILE"
  local _aws_to_show
  local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-$AWS_PROFILE_REGION}}"
  local color=yellow

  if [[ -n "$AWS_PROFILE" ]];then
    _aws_to_show+="${ZSH_THEME_AWS_PROFILE_PREFIX="<aws:"}${AWS_PROFILE}${ZSH_THEME_AWS_PROFILE_SUFFIX=">"}"
  fi

  if [[ -n "$region" ]]; then
    [[ -n "$_aws_to_show" ]] && _aws_to_show+="${ZSH_THEME_AWS_DIVIDER=" "}"
    _aws_to_show+="${ZSH_THEME_AWS_REGION_PREFIX="<region:"}${region}${ZSH_THEME_AWS_REGION_SUFFIX=">"}"
  fi

  if [[ "$aws_profile" =~ ".*prod.*" ]]; then
    color=red
  fi

  prompt_segment default $color "$_aws_to_show"
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%b%}"
  CURRENT_BG=''
}

## Main prompt
build_prompt() {
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

build_rprompt() {
  RETVAL=$?
  prompt_aws2
  prompt_docker
  prompt_kubernetes
	prompt_status
}

rp_toggle() {
  if [ -z "$RPROMPT_TOGGLE" ]; then
    export RPROMPT_TOGGLE=1
    export RPROMPT='%{%f%B%k%}$(build_rprompt)'
  else
    unset  RPROMPT_TOGGLE
    export RPROMPT='%{%f%B%k%}$(prompt_status)'
  fi
}

zle -N rp_toggle
bindkey '^t' rp_toggle

RPROMPT='%{%f%B%k%}$(build_rprompt)'
PROMPT='%{%f%B%k%}$(build_prompt) '
