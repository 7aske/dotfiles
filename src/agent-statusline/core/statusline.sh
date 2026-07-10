#!/usr/bin/env bash
# Shared agent status line.
# Mirrors info from agnoster-custom.zsh-theme: user@host, dir, git, AWS, model, context
#
# stdin: canonical statusline payload
#   { cwd, model: { display_name }, context_window: { ... } }

set -euo pipefail

input=$(cat)

user=$(whoami)
host=$(hostname)

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
dir=$(basename "$cwd")

git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  unstaged=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  if [ "$unstaged" -gt 0 ]; then
    git_info="+-${unstaged} ${branch}"
  else
    git_info=" ${branch}"
  fi
fi

kube_info=""
kube_config="${KUBECONFIG:-$HOME/.kube/config}"
if [ -f "$kube_config" ]; then
  current_ctx=$(awk '$1 == "current-context:" {
    if ($2 ~ /^".*"$/) { print substr($2, 2, length($2) - 2) } else { print $2 }
  }' "$kube_config" 2>/dev/null)
  if [ -n "$current_ctx" ]; then
    current_ns=$(kubens -c 2>/dev/null || true)
    if [ -n "$current_ns" ] && [ "$current_ns" != "default" ]; then
      kube_info="${current_ns}:${current_ctx}"
    else
      kube_info="${current_ctx}"
    fi
  fi
fi

AWS_REGION_FILE="$HOME/.aws_region"
AWS_PROFILE_FILE="$HOME/.aws_profile"
[[ -r $AWS_PROFILE_FILE ]] && source "$AWS_PROFILE_FILE"
[[ -r $AWS_REGION_FILE  ]] && source "$AWS_REGION_FILE"

aws_info=""
aws_profile="${AWS_PROFILE:-}"
aws_region="${AWS_DEFAULT_REGION:-${AWS_REGION:-}}"
if [ -n "$aws_profile" ]; then
  aws_info="${aws_profile}"
  [ -n "$aws_region" ] && aws_info="${aws_info}:${aws_region}"
fi

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
used_tokens=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')
total_tokens=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')

fmt_tokens() {
  echo "$1" | awk '{ if ($1 >= 1000) printf "%.1fk", $1 / 1000; else printf "%d", $1 }'
}

printf "\033[0;33m%s@%s\033[00m \033[0;34m%s\033[00m" "$user" "$host" "$dir"
[ -n "$git_info" ] && printf "  \033[0;32m%s\033[00m" "$git_info"
[ -n "$aws_info" ] && printf "  \033[0;33m%s\033[00m" "$aws_info"

if [ -n "$kube_info" ]; then
  case "$kube_info" in
    *prod*) kube_color="\033[0;31m" ;;
    *)      kube_color="\033[0;34m" ;;
  esac
  printf "  ${kube_color} %s\033[00m" "$kube_info"
fi

printf "  \033[02;37m|\033[00m  "
[ -n "$model" ] && printf "\033[36m%s\033[00m" "$model"

if [ -n "$used" ]; then
  bar_width=10
  filled=$(printf "%.0f" "$(echo "$used $bar_width" | awk '{printf "%f", $1 * $2 / 100}')")
  empty=$((bar_width - filled))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}|"; done
  for i in $(seq 1 "$empty");  do bar="${bar} "; done
  [ -n "$model" ] && printf "  "
  printf "\033[33m[%s]\033[00m \033[33m%.0f%%\033[00m" "$bar" "$used"
  if [ -n "$used_tokens" ] && [ -n "$total_tokens" ]; then
    printf " \033[02;37m(%s/%s)\033[00m" "$(fmt_tokens "$used_tokens")" "$(fmt_tokens "$total_tokens")"
  fi
fi
