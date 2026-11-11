on run argv
	set procName to item 1 of argv
	set ident to item 2 of argv
	tell application "System Events" to tell process procName
		repeat with e in (entire contents of window 1)
			try
				if value of attribute "AXIdentifier" of e is ident then
					perform action "AXPress" of e
					return "pressed " & ident
				end if
			end try
		end repeat
	end tell
	return "not found " & ident
end run
