#!/usr/bin/env bash
# task-agent.sh - open a herdr agent pane primed with context from a Taskwarrior task
set -euo pipefail

task_get() {
	task _get rc.verbose=nothing "$TASK_UUID.$1" 2>/dev/null || true
}

notify() {
	notify-send "task-agent" "$1"
}

# Prefer absolute paths; otherwise resolve relative to $PWD (matches herdr-create elsewhere).
herdr_create() {
	local session_name wid cwd
	local -a args=()

	if [ -d "$1" ]; then
		cwd="$(realpath "$1")"
	else
		cwd="$(realpath "$PWD/$1")"
	fi

	if [ ! -d "$cwd" ]; then
		echo "Directory does not exist: $cwd" >&2
		return 1
	fi

	session_name="$(basename "$cwd")"
	# Labels may be prefixed by plugins; match on suffix.
	wid="$(herdr workspace list | jq -r --arg name "$session_name" \
		'.result.workspaces[] | select(.label | endswith($name)) | .workspace_id' | head -n1)"

	if [ "$session_name" = ".agent" ]; then
		args+=(--label default)
	fi

	if [ -z "$wid" ]; then
		wid="$(herdr workspace create --cwd "$cwd" "${args[@]}" | jq -r .result.workspace.workspace_id)"
	fi

	printf '%s\n' "$wid"
}

fallback_description() {
	local url="$1"
	if [ -n "$url" ]; then
		printf 'Description not available. Open %s for details.\n' "$url"
	else
		printf 'Description not available.\n'
	fi
}

build_jira_prompt() {
	local jiraid url summary status issuetype description
	jiraid="$(task_get jiraid)"
	url="$(task_get jiraurl)"
	summary="$(task_get jirasummary)"
	status="$(task_get jirastatus)"
	issuetype="$(task_get jiraissuetype)"
	description="$(task_get jiradescription)"
	[ -n "$description" ] || description="$(fallback_description "$url")"

	notify "Creating a Jira agent session"
	cat <<EOF
Start working on Jira ticket ${jiraid}${summary:+: $summary}.

Ticket: ${url:-unknown}
Type: ${issuetype:-unknown}
Status: ${status:-unknown}

Description:
$description

Instructions:
1. Read the ticket and explore the relevant parts of the codebase before changing anything.
2. If requirements, acceptance criteria, or scope are unclear, ask me before writing code. Keep questions short and ask them together.
3. Propose a short plan and wait for my confirmation before implementing.
4. Work on a focused branch if needed. Keep commits small. Do not push unless I ask.
5. Follow existing code style and add or update tests where it matters.
6. When done, summarize what changed, how you tested it, and any open questions or follow-ups for the ticket.
EOF
}

build_gitlab_mr_prompt() {
	local mrid url title description namespace localdir state wip
	mrid="$(task_get gitlabnumber)"
	url="$(task_get gitlaburl)"
	title="$(task_get gitlabtitle)"
	description="$(task_get gitlabdescription)"
	namespace="$(task_get gitlabnamespace)"
	state="$(task_get gitlabstate)"
	wip="$(task_get gitlabwip)"
	localdir="$(cgs -C)/$namespace"
	[ -n "$description" ] || description="$(fallback_description "$url")"
	case "$wip" in
	1 | true | yes) state="${state:-unknown} (WIP)" ;;
	*) state="${state:-unknown}" ;;
	esac

	notify "Creating a GitLab MR agent session"
	cat <<EOF
Review GitLab merge request !${mrid}: ${title:-untitled}

MR: ${url:-unknown}
State: $state
Local checkout (if present): $localdir

Description:
$description

Instructions:
1. Use glab from the repo (prefer cd into the local checkout if it exists). Gather context with: glab mr view $mrid --comments and glab mr diff $mrid. Do not modify the working tree, checkout branches, or push.
2. Read surrounding code for context, not just the changed lines.
3. Check for: correctness and edge cases, security issues, error handling, performance, missing or weak tests, breaking API or schema changes, and consistency with existing style.
4. Check whether the implementation matches the MR description and any linked Jira ticket.
5. Report findings grouped by severity (blocking, should-fix, nit). Each finding needs file:line and a suggested fix.
6. Do not post comments to GitLab. Show me a draft review and ask which comments to submit.
7. If anything is unclear, ask before concluding.
EOF
}

build_local_prompt() {
	local localdir description annotations
	localdir="$(task_get localdir)"
	description="$(task_get description)"
	annotations="$(task_get annotations)"

	notify "Creating a coding agent session"
	cat <<EOF
Start working on the following task in the repository at $localdir.

Task:
$description

Notes:
${annotations:-none}

Instructions:
1. Explore first (structure, README, relevant code, recent git log, and that remotes/branches are fetched) before changing anything.
2. If the task is ambiguous or you need more information, ask me before writing code. Keep questions short and ask them together.
3. Propose a short plan and wait for my confirmation before implementing.
4. Use a new branch if needed. Keep commits small and focused. Do not push unless I ask.
5. Follow existing code style and add or update tests where applicable.
6. When done, summarize what changed, how you tested it, and any open questions.
EOF
}

build_generic_prompt() {
	local description project due annotations
	description="$(task_get description)"
	[ -n "$description" ] || return 1
	project="$(task_get project)"
	due="$(task_get due)"
	annotations="$(task_get annotations)"

	notify "Creating a generic agent session"
	cat <<EOF
Help me get the following to-do done.

Task:
$description

Project: ${project:-none}
Due: ${due:-none}

Notes:
${annotations:-none}

Instructions:
1. Say in one line what kind of task this is (research, writing, admin, coding, planning, decision).
2. If the goal, scope, or desired outcome is unclear, ask me before doing anything else. Keep questions short and ask them together.
3. Break the task into concrete steps. Mark which ones you can do and which need me (accounts, payments, calls, physical actions).
4. Do the steps you can. Draft emails, messages, or documents instead of sending them. Do not purchase, delete, or change external systems without asking.
5. Prefer the simplest approach, and an existing service over building something custom when the task is not technical.
6. Finish with: what is done, what is left for me (checklist), and any deadlines or risks.
EOF
}

main() {
	local TASK_UUID jiraid gitlabtype localdir prompt wid
	TASK_UUID="${1:-}"
	if [ -z "$TASK_UUID" ]; then
		echo "Usage: $0 <task-uuid>" >&2
		exit 1
	fi

	jiraid="$(task_get jiraid)"
	gitlabtype="$(task_get gitlabtype)"
	localdir="$(task_get localdir)"

	if [ -n "$jiraid" ]; then
		prompt="$(build_jira_prompt)"
	elif [ "$gitlabtype" = "merge_request" ]; then
		localdir="$(cgs -C)/$(task_get gitlabnamespace)"
		prompt="$(build_gitlab_mr_prompt)"
	elif [ -n "$localdir" ] && [ -d "$localdir" ]; then
		prompt="$(build_local_prompt)"
	else
		localdir="$HOME/.agent"
		prompt="$(build_generic_prompt)" || exit 0
	fi

	# Coding tasks need the repo; Jira/MR can fall back to the generic agent home.
	if [ ! -d "$localdir" ]; then
		localdir="$HOME/.agent"
	fi

	wid="$(herdr_create "$localdir")"
	herdr pane run "$wid:p1" "agent $(printf '%q' "$prompt")"
}

main "$@"
