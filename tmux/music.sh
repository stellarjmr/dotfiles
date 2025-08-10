#!/usr/bin/env osascript
# Returns the current playing song from either Spotify or Apple Music for OSX

on formatTrackInfo(track_name, artist_name, app_icon)
	if artist_name > 0
		# If the track has an artist set and is therefore most likely a song rather than an advert
		set t to app_icon & " " & artist_name & " - " & track_name
		if length of t > 35
			return text 1 thru 35 of t & "..."
		else
			return app_icon & " " & artist_name & " - " & track_name
		end if
	else
		# If the track doesn't have an artist set and is therefore most likely an advert rather than a song
		return "~ " & track_name
	end if
end formatTrackInfo

try
	tell application "Spotify"
		if it is running then
			if player state is playing then
				set track_name to name of current track
				set artist_name to artist of current track
				return my formatTrackInfo(track_name, artist_name, " ")
			end if
		end if
	end tell
end try

try
	tell application "Music"
		if it is running then
			if player state is playing then
				set track_name to name of current track
				set artist_name to artist of current track
				return my formatTrackInfo(track_name, artist_name, " ")
			end if
		end if
	end tell
end try

return ""
