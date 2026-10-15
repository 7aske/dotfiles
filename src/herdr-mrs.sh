#!/usr/bin/env bash
#
# herdr-mrs - fzf TUI listing open merge/pull requests of the repository the
# focused herdr workspace is in (GitLab via glab, GitHub via gh).
#
# usage: herdr-mrs [dir]
#
# keys: enter open in browser | ctrl-r reload | ctrl-o checkout
#       ctrl-y copy url | ctrl-d toggle diff/details | alt-p toggle preview

set -o pipefail

self="$(readlink -f "$0")"

die() {
    printf '%s\n' "$*" >&2
    if [ -t 0 ]; then
        printf 'press any key...' >&2
        read -rsn1
    fi
    exit 1
}

# directory of the focused herdr pane, falling back to the focused workspace's
# first pane (the popup itself may hold focus) and finally $PWD
_herdr_cwd() {
    [ -x "$(command -v herdr)" ] || return 1
    local panes ws
    panes="$(herdr pane list 2>/dev/null)" || return 1
    ws="$(herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | select(.focused) | .workspace_id')"
    jq -r --arg ws "$ws" '
        [.result.panes[] | select(.focused)] + [.result.panes[] | select(.workspace_id == $ws)]
        | map(.foreground_cwd // .cwd) | map(select(. != null)) | first // empty
    ' <<<"$panes"
}

# sets: forge host project
_parse_remote() {
    local url rest
    url="$(git -C "$MRS_DIR" remote get-url origin 2>/dev/null)" ||
        url="$(git -C "$MRS_DIR" remote -v | awk 'NR==1{print $2}')"
    [ -n "$url" ] || return 1

    case "$url" in
    *://*)
        rest="${url#*://}"
        rest="${rest#*@}"
        host="${rest%%/*}"
        host="${host%%:*}"
        project="${rest#*/}"
        ;;
    *@*:*)
        rest="${url#*@}"
        host="${rest%%:*}"
        project="${rest#*:}"
        ;;
    *) return 1 ;;
    esac
    project="${project%.git}"
    project="${project%/}"

    case "$host" in
    *github*) forge=github ;;
    *) forge=gitlab ;;
    esac
}

# normalized JSON array of open MRs
_fetch() {
    case "$MRS_FORGE" in
    gitlab)
        # shellcheck disable=SC2016
        glab api graphql --hostname "$MRS_HOST" -f p="$MRS_PROJECT" -f query='
            query($p: ID!) {
              project(fullPath: $p) {
                mergeRequests(state: opened, sort: UPDATED_DESC, first: 100) {
                  nodes {
                    iid title description draft webUrl sourceBranch targetBranch updatedAt
                    detailedMergeStatus conflicts approved approvalsLeft userNotesCount
                    author { username }
                    reviewers { nodes { username } }
                    approvedBy { nodes { username } }
                    headPipeline { status }
                    diffStatsSummary { additions deletions }
                  }
                }
              }
            }' | jq '
            if .errors then error(.errors | map(.message) | join("; ")) else . end
            | (.data.project // error("project not found: '"$MRS_PROJECT"'"))
            | .mergeRequests.nodes
            | map({
                id: .iid, title, description, draft, url: .webUrl,
                source: .sourceBranch, target: .targetBranch, updated: .updatedAt,
                author: .author.username,
                pipeline: .headPipeline.status,
                merge: .detailedMergeStatus,
                conflicts, approved, approvalsLeft,
                approvedBy: [.approvedBy.nodes[].username],
                reviewers: [.reviewers.nodes[].username],
                notes: .userNotesCount,
                adds: .diffStatsSummary.additions, dels: .diffStatsSummary.deletions
              })'
        ;;
    github)
        gh pr list -R "$MRS_HOST/$MRS_PROJECT" --state open --limit 30 --json \
            number,title,body,isDraft,url,headRefName,baseRefName,updatedAt,mergeable,mergeStateStatus,reviewDecision,author,reviewRequests,latestReviews,statusCheckRollup,additions,deletions |
            jq 'map({
                id: (.number | tostring), title, description: .body, draft: .isDraft, url,
                source: .headRefName, target: .baseRefName, updated: .updatedAt,
                author: .author.login,
                pipeline: (
                    [.statusCheckRollup[]? | (.conclusion // .state // .status // "" | ascii_upcase)] as $s
                    | if ($s | length) == 0 then null
                      elif any($s[]; IN("FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED")) then "FAILED"
                      elif any($s[]; IN("", "PENDING", "QUEUED", "IN_PROGRESS", "EXPECTED", "WAITING")) then "RUNNING"
                      else "SUCCESS" end),
                merge: (if .mergeable == "CONFLICTING" then "CONFLICT"
                        elif .reviewDecision == "CHANGES_REQUESTED" then "REQUESTED_CHANGES"
                        elif .reviewDecision == "REVIEW_REQUIRED" then "NOT_APPROVED"
                        elif .mergeStateStatus == "CLEAN" then "MERGEABLE"
                        else .mergeStateStatus end),
                conflicts: (.mergeable == "CONFLICTING"),
                approved: (.reviewDecision == "APPROVED" or .reviewDecision == null or .reviewDecision == ""),
                approvalsLeft: (if .reviewDecision == "APPROVED" then 0 else null end),
                approvedBy: [.latestReviews[]? | select(.state == "APPROVED") | .author.login],
                reviewers: [.reviewRequests[]? | (.login // .name // .slug)],
                notes: null,
                adds: .additions, dels: .deletions
              })'
        ;;
    esac
}

# shared jq helpers (colors + status words)
# shellcheck disable=SC2016
JQ_LIB='
def c(n): "\u001b[\(n)m" + . + "\u001b[0m";
def pad(n): tostring | if length > n then .[:n-1] + "…" else . + (" " * (n - length)) end;
def ago: (now - (sub("\\.[0-9]+"; "") | fromdateiso8601)) as $s
    | if $s < 3600 then "\($s / 60 | floor)m"
      elif $s < 86400 then "\($s / 3600 | floor)h"
      else "\($s / 86400 | floor)d" end;
def ci: {
    SUCCESS: ["✓ pass", "32"], FAILED: ["✗ fail", "31"], RUNNING: ["● run", "33"],
    PENDING: ["○ pend", "33"], CREATED: ["○ new", "33"], PREPARING: ["○ prep", "33"],
    WAITING_FOR_RESOURCE: ["○ wait", "33"], SCHEDULED: ["○ sched", "33"],
    MANUAL: ["▶ manual", "35"], CANCELED: ["⊘ cancel", "90"], CANCELING: ["⊘ cancel", "90"],
    SKIPPED: ["» skip", "90"]
  }[. // ""] // ["- none", "90"];
def mstate: if .draft then ["draft", "90"]
    elif .conflicts then ["conflict", "31"]
    else {
      MERGEABLE: ["ready", "32"], CONFLICT: ["conflict", "31"], NEED_REBASE: ["rebase", "31"],
      BEHIND: ["rebase", "31"], DIRTY: ["conflict", "31"],
      NOT_APPROVED: ["review", "33"], REQUESTED_CHANGES: ["changes", "31"],
      DISCUSSIONS_NOT_RESOLVED: ["threads", "33"], CI_MUST_PASS: ["ci", "33"],
      CI_STILL_RUNNING: ["ci", "33"], BLOCKED_STATUS: ["blocked", "31"], BLOCKED: ["blocked", "31"],
      DRAFT_STATUS: ["draft", "90"], NOT_OPEN: ["closed", "90"], UNSTABLE: ["unstable", "33"],
      JIRA_ASSOCIATION_MISSING: ["jira", "33"], EXTERNAL_STATUS_CHECKS: ["ext-check", "33"],
      CHECKING: ["checking", "90"], UNCHECKED: ["checking", "90"], PREPARING: ["checking", "90"]
    }[.merge // ""] // [(.merge // "?" | ascii_downcase), "90"] end;
def appr: if .approved and (.approvalsLeft // 0) == 0 then
      ["✓" + (.approvedBy | length | if . > 0 then " \(.)" else "" end), "32"]
    elif .approvalsLeft then ["\(.approvalsLeft) left", "33"]
    else ["-", "90"] end;
'

_list() {
    local json="$MRS_CACHE/mrs.json"
    _fetch >"$json.tmp" || {
        printf '\t\033[31mfailed to fetch MRs (see stderr above)\033[0m\n'
        return
    }
    mv "$json.tmp" "$json"
    jq -r "$JQ_LIB"'
        if length == 0 then "\t\u001b[90mno open merge requests\u001b[0m" else .[] |
        [ .id,
          ("!" + .id | pad(6) | c("1;36")),
          (.pipeline | ci as $x | $x[0] | pad(9) | c($x[1])),
          (mstate as $x | $x[0] | pad(10) | c($x[1])),
          (appr as $x | $x[0] | pad(7) | c($x[1])),
          (.author | pad(14) | c("34")),
          (.updated | ago | pad(4) | c("90")),
          .title
        ] | join("\t") end' "$json"
}

_preview() {
    local id="$1"
    [ -n "$id" ] || return 0
    jq -r --arg id "$id" "$JQ_LIB"'
        .[] | select(.id == $id) |
        "\("!" + .id | c("1;36")) \(.title | c("1"))",
        "",
        "  branch    \(.source | c("35")) → \(.target | c("35"))",
        "  author    \(.author | c("34"))   updated \(.updated | ago) ago",
        "  pipeline  \(.pipeline | ci as $x | $x[0] | c($x[1]))",
        "  status    \(mstate as $x | $x[0] | c($x[1]))\(if .merge then "  (" + (.merge | ascii_downcase) + ")" else "" end)",
        "  approvals \(appr as $x | $x[0] | c($x[1]))\(if (.approvedBy | length) > 0 then "  by " + (.approvedBy | join(", ")) else "" end)",
        "  reviewers \(if (.reviewers | length) > 0 then .reviewers | join(", ") else "-" end)",
        "  diff      \("+\(.adds // 0)" | c("32")) \("-\(.dels // 0)" | c("31"))\(if .notes then "   comments \(.notes)" else "" end)",
        "  url       \(.url | c("4"))",
        "",
        (.description // "" | gsub("\r"; ""))
    ' "$MRS_CACHE/mrs.json"
}

_diff() {
    local id="$1"
    [ -n "$id" ] || return 0
    cd "$MRS_DIR" || return
    case "$MRS_FORGE" in
    gitlab) glab mr diff "$id" -R "$MRS_HOST/$MRS_PROJECT" --color=always ;;
    github) gh pr diff "$id" -R "$MRS_HOST/$MRS_PROJECT" --color=always ;;
    esac
}

_checkout() {
    local id="$1"
    [ -n "$id" ] || return 0
    cd "$MRS_DIR" || return
    case "$MRS_FORGE" in
    gitlab) glab mr checkout "$id" ;;
    github) gh pr checkout "$id" ;;
    esac
    printf '\npress any key...'
    read -rsn1
}

_url() {
    jq -r --arg id "$1" '.[] | select(.id == $id) | .url' "$MRS_CACHE/mrs.json"
}

_open() {
    local url
    url="$(_url "$1")"
    [ -n "$url" ] && xdg-open "$url" >/dev/null 2>&1 &
}

_copy() {
    local url
    url="$(_url "$1")"
    [ -n "$url" ] || return 0
    if [ -n "$WAYLAND_DISPLAY" ] && [ -x "$(command -v wl-copy)" ]; then
        printf '%s' "$url" | wl-copy
    elif [ -x "$(command -v xclip)" ]; then
        printf '%s' "$url" | xclip -selection clipboard
    else
        printf '\033]52;c;%s\a' "$(printf '%s' "$url" | base64 -w0)" >/dev/tty
    fi
}

# internal subcommands invoked from fzf bindings
case "$1" in
_list | _preview | _diff | _checkout | _open | _copy)
    cmd="$1"
    shift
    "$cmd" "$@"
    exit
    ;;
esac

for dep in git jq fzf; do
    [ -x "$(command -v "$dep")" ] || die "$dep: command not found"
done

MRS_DIR="${1:-$(_herdr_cwd)}"
MRS_DIR="${MRS_DIR:-$PWD}"
MRS_DIR="$(git -C "$MRS_DIR" rev-parse --show-toplevel 2>/dev/null)" ||
    die "not a git repository: ${1:-$MRS_DIR}"

_parse_remote || die "no usable git remote in $MRS_DIR"

case "$forge" in
gitlab) [ -x "$(command -v glab)" ] || die "glab: command not found" ;;
github) [ -x "$(command -v gh)" ] || die "gh: command not found" ;;
esac

MRS_FORGE="$forge"
MRS_HOST="$host"
MRS_PROJECT="$project"
MRS_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/herdr-mrs.XXXXXX")"
export MRS_DIR MRS_FORGE MRS_HOST MRS_PROJECT MRS_CACHE
trap 'rm -rf "$MRS_CACHE"' EXIT

label="MRs"
[ "$forge" = github ] && label="PRs"

# shellcheck disable=SC2016
FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-}" fzf \
    --ansi \
    --no-sort \
    --delimiter='\t' \
    --with-nth='2..' \
    --layout=reverse \
    --border=rounded \
    --border-label=" 󰓦 $label · $project " \
    --header='enter open · ctrl-r reload · ctrl-o checkout · ctrl-y copy url · ctrl-d diff · alt-p preview' \
    --header-first \
    --prompt="$label> " \
    --preview-window='down,60%,wrap,border-top' \
    --preview="$self _preview {1}" \
    --bind="start:reload($self _list)" \
    --bind="ctrl-r:reload($self _list)" \
    --bind="enter:execute-silent($self _open {1})" \
    --bind="ctrl-y:execute-silent($self _copy {1})" \
    --bind="ctrl-o:execute($self _checkout {1})" \
    --bind="ctrl-d:transform:[[ \$FZF_PREVIEW_LABEL =~ diff ]] && echo 'change-preview-label()+change-preview($self _preview {1})' || echo 'change-preview-label( diff )+change-preview($self _diff {1})'" \
    --bind='alt-p:toggle-preview' \
    --bind='esc:abort' \
    </dev/null
