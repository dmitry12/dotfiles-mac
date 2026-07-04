#!/usr/bin/env bash
# Toggle sketchybar visibility AND collapse/restore the AeroSpace gap it reserves.
# AeroSpace has no runtime gap command, so we rewrite the config and reload.
# `> file` truncates in place to preserve the dotfiles<->~/.config hardlink.
set -euo pipefail

CONFIG="$HOME/.config/aerospace/aerospace.toml"
SHOWN='outer.top = [{ monitor."DELL U3417W" = 37 }, { monitor."Built-in Retina Display" = 8 }, 5]'
HIDDEN='outer.top = [{ monitor."DELL U3417W" = 5 }, { monitor."Built-in Retina Display" = 5 }, 5]'

content=$(cat "$CONFIG")
if [[ "$content" == *"$SHOWN"* ]]; then
	# currently shown -> hide bar + collapse gap
	sketchybar --bar hidden=on
	content=${content//"$SHOWN"/"$HIDDEN"}
else
	# currently hidden -> show bar + restore gap
	sketchybar --bar hidden=off
	content=${content//"$HIDDEN"/"$SHOWN"}
fi

printf '%s\n' "$content" >"$CONFIG"
aerospace reload-config
