#!/usr/bin/env bash
set -euo pipefail

launch() {
  if pgrep -xq "$1"; then
    echo "$1 already running"
  else
    open -ga "$1"
  fi
}

launch "Google Chrome"
launch "Ghostty"
launch "Claude"
launch "Slack"
launch "Visual Studio Code"
launch "Obsidian"

# Poll until windows appear (max 10s at 0.5s intervals)
for _ in $(seq 1 20); do
  count=$(aerospace list-windows --all 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -ge 6 ] && break
  sleep 0.5
done

sleep 3

aerospace workspace 5
