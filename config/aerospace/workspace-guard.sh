#!/usr/bin/env bash
# Chromium background makeKeyAndOrderFront: calls steal focus back shortly after a
# workspace switch (https://github.com/nikitabobko/AeroSpace/issues/726).
# Observed steal window on this machine: ~0.5-1.5s after the switch.
# This guard re-asserts the workspace the user explicitly switched to, but only
# when the thief is a Chromium-family app, so genuine user focus changes win.
set -u

AEROSPACE=/opt/homebrew/bin/aerospace
ws="${1:-$($AEROSPACE list-workspaces --focused)}"
state="${TMPDIR:-/tmp}/aerospace-workspace-guard"

# Latest keypress wins: newer guard instances overwrite this and older ones exit.
echo "$ws" >"$state"

# Poll fast so the correction is near-instant; cover the whole ~2.5s steal window.
for _ in $(seq 1 16); do
  sleep 0.15
  [ "$(cat "$state" 2>/dev/null)" = "$ws" ] || exit 0
  focused="$($AEROSPACE list-workspaces --focused)"
  [ "$focused" = "$ws" ] && continue
  app="$($AEROSPACE list-windows --focused --format '%{app-name}' 2>/dev/null)"
  case "$app" in
  "Google Chrome" | "Google Chrome Beta" | "Chromium" | "Arc")
    $AEROSPACE workspace "$ws"
    ;;
  *)
    # Focus moved for another reason (likely the user) - stand down.
    exit 0
    ;;
  esac
done
