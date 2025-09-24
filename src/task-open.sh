#!/usr/bin/env bash
# task-open.sh - open the first URL found in the annotations of a Taskwarrior task

# Get UUID of the selected task from taskwarrior-tui
TASK_UUID="$1"
if [ -z "$TASK_UUID" ]; then
  echo "Usage: $0 <task-uuid>"
  exit 1
fi

# Extract annotations of the task
ANNOTATION_COUNT="$(task _get rc.verbose=nothing "$TASK_UUID".annotations.count)"
for i in $(seq 1 "$ANNOTATION_COUNT"); do
  ANNOTATIONS+=$(task _get rc.verbose=nothing "$TASK_UUID".annotations.$i.description)
done

# Look for the first URL
URL=$(echo "$ANNOTATIONS" | grep -Eo 'https?://[^ ]+' | head -n1)

if [ -z "$URL" ]; then
  notify-send "task-open" "No URL found in annotations for task $TASK_UUID"
  exit 1
fi

# Detect OS and open URL
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL"
elif command -v open >/dev/null 2>&1; then
  open "$URL"
else
  notify-send "task-open" "Don't know how to open URLs on this system."
  exit 1
fi

