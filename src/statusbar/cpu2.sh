#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

PREV_TOTAL=0
PREV_IDLE=0

while true; do
  CPU=(`cat /proc/stat | grep '^cpu '`) # Get the total CPU statistics.
  unset CPU[0]                          # Discard the "cpu" prefix.
  IDLE=${CPU[4]}                        # Get the idle CPU time.

  # Calculate the total CPU time.
  TOTAL=0

  for VALUE in "${CPU[@]:0:4}"; do
    let "TOTAL=$TOTAL+$VALUE"
  done

  # Calculate the CPU usage since we last checked.
  let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  let "cpu_usage=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"

  if [ "$cpu_usage" -ge 75 ]; then
      icon="󰡴"
      color="${color1:-"#BF616A"}"
  elif [ "$cpu_usage" -ge 50 ]; then
      icon="󰊚"
      color="${color3:-"#D08770"}"
  elif [ "$cpu_usage" -ge 25 ]; then
      icon="󰡵"
      color="${color2:-"#EBCB8B"}"
  else
      icon="󰡳"
      color="${color7:-"#D8DEE9"}"
  fi

  # Remember the total and idle CPU times for the next check.
  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"


  if [ -e "$SWITCH" ]; then
      printf "<span color='%s' size='large'>%s </span>\n" "$color" "$icon"
  else
      printf "<span size='large'>$icon</span> <span color='%s'>%3d%%</span>\n" "$color" "$cpu_usage"
  fi

  # Wait before checking again.
  sleep 1
done
