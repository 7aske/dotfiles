#!/usr/bin/env bash
# Merge dotfiles-managed statusLine into Claude settings.json.
# Matches by command path: updates managed entry, preserves everything else.

set -euo pipefail

usage() {
  echo "usage: merge-statusline-json.sh <src_manifest> <dst_file> [--remove]" >&2
  exit 2
}

[ $# -lt 2 ] && usage

src=$1
dst=$2
remove=${3:-}

[ -f "$src" ] || { echo "merge-statusline-json: missing manifest: $src" >&2; exit 1; }
command -v jq >/dev/null || { echo "merge-statusline-json: jq is required" >&2; exit 1; }

managed_command=$(jq -r '.statusLine.command // empty' "$src")
[ -n "$managed_command" ] || {
  echo "merge-statusline-json: missing statusLine.command in $src" >&2
  exit 1
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if [ -f "$dst" ]; then
  base=$(cat "$dst")
else
  base='{}'
fi

if [ "$remove" = --remove ]; then
  jq --arg cmd "$managed_command" '
    if .statusLine.command == $cmd then del(.statusLine) else . end
  ' <<<"$base" >"$tmp"
else
  jq -s --slurpfile src "$src" '
    .[0] * $src[0]
  ' <(printf '%s' "$base") >"$tmp"
fi

mkdir -p "$(dirname "$dst")"
mv "$tmp" "$dst"
trap - EXIT
printf '%s\n' "$dst"
