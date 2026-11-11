#!/bin/bash
# Brings both apps back without overrides and shows again the apps that were visible.
DIR="$(cd "$(dirname "$0")" && pwd)"
for id in atyp.makers.timer.app com.local.screenlight; do osascript -e "tell application id \"$id\" to quit" 2>/dev/null; done
for _ in $(seq 40); do pgrep -x Timer >/dev/null || pgrep -x ScreenLight >/dev/null || break; sleep 0.25; done
sleep 1
open "/Applications/Timer.app"; open "/Applications/Screen Light.app"; sleep 4
IFS=, read -ra APPS < "$DIR/hidden-apps.txt"
for a in "${APPS[@]}"; do
	osascript -e "tell application \"System Events\" to if exists process \"$a\" then set visible of process \"$a\" to true" 2>/dev/null
done
# anything of ours that wasn't visible before goes back to hidden
for p in Timer ScreenLight; do
	case ",$(cat "$DIR/hidden-apps.txt")," in *",$p,"*) ;; *) osascript -e "tell application \"System Events\" to set visible of process \"$p\" to false" 2>/dev/null;; esac
done
osascript -e 'tell application "System Events" to get name of every process whose visible is true and background only is false'
