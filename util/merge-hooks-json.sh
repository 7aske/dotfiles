#!/usr/bin/env bash
# Merge dotfiles-managed hook entries into Cursor or Claude config.
# Matches by command path: updates managed entries, preserves everything else.

set -euo pipefail

usage() {
  echo "usage: merge-hooks-json.sh <cursor|claude> <src_manifest> <dst_file> [--remove]" >&2
  exit 2
}

[ $# -lt 3 ] && usage

kind=$1
src=$2
dst=$3
remove=${4:-}

[ -f "$src" ] || { echo "merge-hooks-json: missing manifest: $src" >&2; exit 1; }
command -v jq >/dev/null || { echo "merge-hooks-json: jq is required" >&2; exit 1; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

case "$kind" in
  cursor)
  if [ -f "$dst" ]; then
    base=$(cat "$dst")
  else
    base='{"version":1,"hooks":{}}'
  fi

  if [ "$remove" = --remove ]; then
    jq -s --slurpfile src "$src" '
      def managed_commands:
        [$src[0].hooks[][]? | .command];

      ($src[0] | managed_commands) as $cmds |
      .[0] |
      if .hooks then . else . + {version: 1, hooks: {}} end |
      .hooks |= with_entries(
        .value |= map(select(.command as $c | ($cmds | index($c)) | not))
      ) |
      .hooks |= with_entries(select(.value | length > 0))
    ' <(printf '%s' "$base") >"$tmp"
  else
    jq -s --slurpfile src "$src" '
      def managed_commands:
        [$src[0].hooks[][]? | .command];

      ($src[0] | managed_commands) as $cmds |
      .[0] as $dst |
      $src[0] as $src |
      ($dst | if .hooks then . else . + {version: 1, hooks: {}} end) |
      .version = ($src.version // .version // 1) |
      .hooks |= with_entries(
        .value |= map(select(.command as $c | ($cmds | index($c)) | not))
      ) |
      reduce ($src.hooks | to_entries[]) as $event (.;
        .hooks[$event.key] = ((.hooks[$event.key] // []) + $event.value)
      )
    ' <(printf '%s' "$base") >"$tmp"
  fi
  ;;

  claude)
  if [ -f "$dst" ]; then
    base=$(cat "$dst")
  else
    base='{}'
  fi

  if [ "$remove" = --remove ]; then
    jq -s --slurpfile src "$src" '
      def managed_commands:
        [$src[0][][]? | .hooks[]? | .command];

      ($src[0] | managed_commands) as $cmds |
      .[0] |
      if .hooks then . else . + {hooks: {}} end |
      .hooks |= with_entries(
        .value |= (
          map(.hooks |= map(select(.command as $c | ($cmds | index($c)) | not)))
          | map(select(.hooks | length > 0))
        )
      ) |
      .hooks |= with_entries(select(.value | length > 0))
    ' <(printf '%s' "$base") >"$tmp"
  else
    jq -s --slurpfile src "$src" '
      def managed_commands:
        [$src[0][][]? | .hooks[]? | .command];

      ($src[0] | managed_commands) as $cmds |
      .[0] as $settings |
      $src[0] as $src_hooks |
      ($settings | if .hooks then . else . + {hooks: {}} end) |
      .hooks |= with_entries(
        .value |= (
          map(.hooks |= map(select(.command as $c | ($cmds | index($c)) | not)))
          | map(select(.hooks | length > 0))
        )
      ) |
      reduce ($src_hooks | to_entries[]) as $event (.;
        .hooks[$event.key] = ((.hooks[$event.key] // []) + $event.value)
      )
    ' <(printf '%s' "$base") >"$tmp"
  fi
  ;;

  *)
  echo "merge-hooks-json: unknown kind: $kind (expected cursor or claude)" >&2
  exit 2
  ;;
esac

mkdir -p "$(dirname "$dst")"
mv "$tmp" "$dst"
trap - EXIT
printf '%s\n' "$dst"
