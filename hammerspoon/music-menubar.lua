-- Music Menubar for Hammerspoon
-- Shows currently playing track from Spotify or Apple Music in menubar

local musicMenubar = hs.menubar.new()
local updateTimer = nil

-- AppleScript to get current playing track
local function getCurrentTrack()
	local script = [[
        -- Function to format track info
        on formatTrackInfo(track_name, artist_name, app_icon)
            if artist_name > 0
                set t to app_icon & " " & artist_name & " - " & track_name
                if length of t > 35
                    return text 1 thru 35 of t & "..."
                else
                    return app_icon & " " & artist_name & " - " & track_name
                end if
            else
                return "~ " & track_name
            end if
        end formatTrackInfo

        -- Check Spotify first
        -- try
        --     tell application "Spotify"
        --         if it is running then
        --             if player state is playing then
        --                 set track_name to name of current track
        --                 set artist_name to artist of current track
        --                 return my formatTrackInfo(track_name, artist_name, "􂙩")
        --             end if
        --         end if
        --     end tell
        -- end try

        -- Check Apple Music if Spotify is not playing
        try
            tell application "Music"
                if it is running then
                    if player state is playing then
                        set track_name to name of current track
                        set artist_name to artist of current track
                        return my formatTrackInfo(track_name, artist_name, "􀑪")
                    end if
                end if
            end tell
        end try

        -- If neither is playing
        return ""
    ]]

	local success, result = hs.osascript.applescript(script)
	if success then
		return result
	else
		return ""
	end
end

-- Update menubar with current track
local function updateMenubar()
	local currentTrack = getCurrentTrack()

	if currentTrack and currentTrack ~= "" then
		musicMenubar:setTitle(currentTrack)
		musicMenubar:setTooltip("Currently playing: " .. currentTrack)
	else
		musicMenubar:setTitle("􀑪 No Music")
		musicMenubar:setTooltip("No music currently playing")
	end
end

-- Menu items
local function createMenu()
	local menuItems = {}

	-- Refresh item
	table.insert(menuItems, {
		title = "􂣼 Refresh",
		fn = function()
			updateMenubar()
		end,
	})

	-- Separator
	table.insert(menuItems, { title = "-" })

	-- Spotify controls
	table.insert(menuItems, {
		title = "􂙩 Spotify",
		menu = {
			{
				title = "􁚞 Play/Pause",
				fn = function()
					hs.osascript.applescript('tell application "Spotify" to playpause')
					hs.timer.doAfter(0.5, updateMenubar)
				end,
			},
			{
				title = "􁋰 Next",
				fn = function()
					hs.osascript.applescript('tell application "Spotify" to next track')
					hs.timer.doAfter(0.5, updateMenubar)
				end,
			},
			{
				title = "􁋮 Previous",
				fn = function()
					hs.osascript.applescript('tell application "Spotify" to previous track')
					hs.timer.doAfter(0.5, updateMenubar)
				end,
			},
		},
	})

	-- Apple Music controls
	table.insert(menuItems, {
		title = "􀑪 Apple Music",
		menu = {
			{
				title = "􁚞 Play/Pause",
				fn = function()
					hs.osascript.applescript('tell application "Music" to playpause')
					hs.timer.doAfter(0.5, updateMenubar)
				end,
			},
			{
				title = "􁋰 Next",
				fn = function()
					hs.osascript.applescript('tell application "Music" to next track')
					hs.timer.doAfter(0.5, updateMenubar)
				end,
			},
			{
				title = "􁋮 Previous",
				fn = function()
					hs.osascript.applescript('tell application "Music" to previous track')
					hs.timer.doAfter(0.5, updateMenubar)
				end,
			},
		},
	})

	-- Separator
	table.insert(menuItems, { title = "-" })

	-- Settings
	table.insert(menuItems, {
		title = "􀍟 Settings",
		menu = {
			{
				title = "􂣼 Auto-refresh: " .. (updateTimer and "ON" or "OFF"),
				fn = function()
					if updateTimer then
						updateTimer:stop()
						updateTimer = nil
					else
						updateTimer = hs.timer.new(30, updateMenubar):start()
					end
				end,
			},
		},
	})

	return menuItems
end

-- Initialize menubar
local function initMusicMenubar()
	if musicMenubar then
		musicMenubar:setMenu(createMenu)
		updateMenubar()

		-- Start auto-refresh timer (updates every 2 seconds)
		updateTimer = hs.timer.new(30, updateMenubar):start()
	end
end

-- Clean up when reloading
local function cleanupMusicMenubar()
	if updateTimer then
		updateTimer:stop()
		updateTimer = nil
	end
	if musicMenubar then
		musicMenubar:delete()
		musicMenubar = nil
	end
end

-- Initialize
initMusicMenubar()

-- Make sure to clean up when Hammerspoon reloads
hs.shutdownCallback = cleanupMusicMenubar
