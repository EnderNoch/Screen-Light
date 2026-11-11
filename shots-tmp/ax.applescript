on run argv
	set procName to item 1 of argv
	set out to ""
	tell application "System Events" to tell process procName
		set els to entire contents of window 1
		repeat with e in els
			try
				if role of e is "AXButton" then set out to out & (name of e as text) & " | " & (description of e as text) & " | " & (enabled of e as text) & linefeed
			end try
		end repeat
	end tell
	return out
end run
