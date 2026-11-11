on run argv
	set procName to item 1 of argv
	set out to ""
	tell application "System Events" to tell process procName
		set els to entire contents of window 1
		set i to 0
		repeat with e in els
			try
				if role of e is "AXButton" then
					set i to i + 1
					set t to ""
					try
						set t to value of attribute "AXTitle" of e
					end try
					set h to ""
					try
						set h to value of attribute "AXHelp" of e
					end try
					set kids to ""
					try
						repeat with k in (UI elements of e)
							try
								set kids to kids & (value of k as text) & "/" & (description of k as text) & ";"
							end try
						end repeat
					end try
					set out to out & i & ": title=" & t & " help=" & h & " kids=" & kids & linefeed
				end if
			end try
		end repeat
	end tell
	return out
end run
