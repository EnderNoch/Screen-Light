#!/bin/bash
# shootmenu.sh <app path> <bundle id> <process name> <owner name> <out.png> [app launch args...]
# Captures the app's menu bar panel with the menu bar above it. The app runs with per-app
# overrides; other apps are hidden, the app's own window is moved out from under the panel,
# the auto-hidden menu bar is revealed by moving the pointer to the top, and the panel is
# opened and closed by clicking the app's own icon - no keystrokes go to other apps.
set -uo pipefail
APP="$1"; ID="$2"; PROC="$3"; OWNER="$4"; OUT="$5"; shift 5
DIR="$(cd "$(dirname "$0")" && pwd)"
icon_click() {
	read -r IX IY < <(osascript -e "tell application \"System Events\" to tell process \"$PROC\" to get position of menu bar item 1 of menu bar 2" | tr -d ',')
	CX=$((IX + 17))
	"$DIR/move" $CX 0; sleep 1.2; "$DIR/move" $CX 12; sleep 0.5; "$DIR/click" $CX 14
}
osascript -e "tell application id \"$ID\" to quit" 2>/dev/null
for _ in $(seq 40); do pgrep -x "$PROC" >/dev/null || break; sleep 0.25; done
sleep 1
open -n "$APP" --args "$@"; sleep 4
osascript -e "tell application id \"$ID\" to activate"; sleep 2
osascript -e "tell application \"System Events\" to set visible of (every process whose visible is true and background only is false and name is not \"$PROC\") to false" 2>/dev/null
osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set position of window 1 to {40, 110}" 2>/dev/null
sleep 1.5
PID=$(pgrep -x "$PROC")
icon_click; sleep 2
read -r WID L X Y W H REST < <("$DIR/bypid" "$PID" | awk '$2 > 0 && $5 > 150' | head -1)
if [ -z "${WID:-}" ]; then echo "FAILED $OUT: no panel"; exit 1; fi
M=40; RX=$((X-M)); RW=$((W+2*M)); RH=$((Y+H+M))
CL="$("$DIR/clash" "$OWNER" $RX 30 $RW $((RH-30)))"
MAINHIT="$("$DIR/bypid" "$PID" | awk -v rx=$RX -v rw=$RW -v rh=$RH '$2 == 0 && $3 < rx+rw && $3+$5 > rx && $4 < rh {print "own window"}')"
if [ -n "$CL$MAINHIT" ]; then echo "FAILED $OUT: in the frame: $CL $MAINHIT"; icon_click; exit 1; fi
sleep 0.5
screencapture -x -o -R "$RX,0,$RW,$RH" "$OUT"
icon_click
echo "$OUT panel ${W}x${H}"
