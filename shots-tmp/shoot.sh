#!/bin/bash
# shoot.sh <app path> <bundle id> <process name> <window owner name> <out.png> [app launch args...]
# Relaunches the app with per-app appearance overrides (system settings stay untouched),
# puts its window over clean wallpaper with every other app hidden, checks nothing else
# is in the frame, and captures the window with the wallpaper behind its glass.
set -uo pipefail
APP="$1"; ID="$2"; PROC="$3"; OWNER="$4"; OUT="$5"; shift 5
DIR="$(cd "$(dirname "$0")" && pwd)"
hide_others() {
	osascript -e "tell application \"System Events\" to set visible of (every process whose visible is true and background only is false and name is not \"$PROC\") to false" 2>/dev/null
}
osascript -e "tell application id \"$ID\" to quit" 2>/dev/null
for _ in $(seq 40); do pgrep -x "$PROC" >/dev/null || break; sleep 0.25; done
sleep 1
open -n "$APP" --args "$@"; sleep 4
osascript -e "tell application id \"$ID\" to activate"; sleep 1
hide_others
osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set position of window 1 to {780, 110}"; sleep 2
read -r WID X Y W H < <("$DIR/wid" "$OWNER" | sort -k5 -n | tail -1)
M=40
RX=$((X-M)); RY=$((Y-M)); RW=$((W+2*M)); RH=$((H+2*M))
for try in 1 2 3; do
	CL="$("$DIR/clash" "$OWNER" $RX $RY $RW $RH)"
	[ -z "$CL" ] && break
	echo "  in the frame: $CL - hiding"
	hide_others; sleep 2
done
[ -n "$("$DIR/clash" "$OWNER" $RX $RY $RW $RH)" ] && { echo "FAILED $OUT: other windows in the frame"; exit 1; }
# optional step before the shot, e.g. pressing Start
if [ -n "${BEFORE:-}" ]; then eval "$BEFORE"; fi
sleep 1
screencapture -x -o -R "$RX,$RY,$RW,$RH" "$OUT"
if [ -n "${AFTER:-}" ]; then eval "$AFTER"; fi
echo "$OUT ${W}x${H}"
