#!/usr/bin/env bash
set -euo pipefail

close() {
  if pgrep -xq "$1"; then
    osascript -e "tell application \"$1\" to quit"
    echo "Closed $1"
  else
    echo "$1 not running"
  fi
}

close "Google Chrome"
close "Ghostty"
close "Claude"
close "Telegram"
close "Visual Studio Code"
close "ChatGPT"
close "Obsidian"
