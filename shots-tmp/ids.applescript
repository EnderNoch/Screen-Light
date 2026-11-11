on run argv
	set out to ""
	tell application "System Events" to tell process (item 1 of argv)
		repeat with e in (entire contents of window 1)
			try
				set r to role of e
				set i to ""
				try
					set i to value of attribute "AXIdentifier" of e
				end try
				set t to ""
				try
					set t to value of attribute "AXTitle" of e
				end try
				if r is "AXButton" then set out to out & r & " id=" & i & " title=" & t & linefeed
			end try
		end repeat
	end tell
	return out
end run
