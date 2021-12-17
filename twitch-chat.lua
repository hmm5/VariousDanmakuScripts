--twitch vod chat replay plugin for mpv


local opt = {
	-- text styling
--	font = 'Dejavu Sans Mono Book',
--	font = 'Noto Serif',
	font = 'Twitter Color Emoji',
	normal_font_size = 13,
	large_font_size = 30,
	font_size = 0,
	font_colour = 'FFFFFF',
	border_size = 2,
	border_colour = '000000',
	alpha = '00',
	mod_font_colour = '00FF00',
	mod_border_colour = '111111',
	streamer_font_colour = 'FFFFFF',
	streamer_border_colour = '111111',
	marginwidth = 60,
	posX = 50,
	posY = 50,
}

function format_name(name, color, alphatrans)
	local nameFormat = string.format(
			'{\\alpha&H%s&}{\\1c&H%s&}{\\3c&H%s&}{\\bord%f}%s:',
			alphatrans,
			color,
			opt.streamer_border_colour,
			opt.border_size,
			name
	)
	return nameFormat
end

function format_string(message)
	local msgTextFormat = string.format(
		'{\\1c&H%s&}{\\alpha&H%s&}{\\fs%d}{\\fn%s}{\\bord%f}%s',
		opt.font_colour,
		opt.alpha,
		opt.font_size,
		opt.font,
		opt.border_size,
		message
	)
	return msgTextFormat
end

function get_table_size(tablearray)
  size = 1
  while  tablearray[size] do
	size = size + 1
  end
  size = size - 1
  return size
end

function find_space_position(s, MarginSize)
	TempString = s:sub(1,MarginSize)
	TempString = string.reverse(TempString)
	SpacePosition = string.find (TempString, " ")
	if SpacePosition then
		SpacePosition = MarginSize - SpacePosition + 1
	end
	return SpacePosition
end

function pull_msgs()
	local client = "kimne78kx3ncx6brgo4mv6wki5h1ko"

	mp.msg.verbose("Getting new messages")

	if nxt ~= nil then
	    mp.msg.verbose("Using cursor: "..nxt)

	    args = {
		"curl",
		"https://api.twitch.tv/v5/videos/"..video_id.."/comments?cursor="..nxt,
		"-H",
		"Client-ID: "..client,
		"-s"
	    }
	else
	    mp.msg.verbose("Cursor is not set. Using time")

	    local time = mp.get_property("time-pos")
	    args = {
		"curl",
		"https://api.twitch.tv/v5/videos/"..video_id.."/comments?content_offset_seconds="..time,
		"-H",
		"Client-ID: "..client,
		"-s"
	    }
	end

	local json = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
	colorformat = "#%x%x%x%x%x%x"
	nxt = string.match(json.stdout, '"_next":"(.-)"')
--	mp.msg.verbose("Got next cursor: "..nxt)
	local t = {}
	for str in string.gmatch(json.stdout, '"content_offset_seconds":(.-)}}},') do
		msgTime = string.match(str, '[^,]+')
		color = string.match(str, colorformat)
		if (color ~= nil) then
			color = color:sub(2)
		else
			color = opt.streamer_font_colour
		end
		name = string.match(str, '{"display_name":"(.-)",')

		--no nightbot ads
		if (name ~= "Nightbot") then
			local msgText = string.match(str,'{"body":"(.-)",')

			if (msgText ~= nil) then
				local msgText = msgText:gsub('\\u003e','>'):gsub('\\u003c','<'):gsub('\\u0026','&')
				local msgText = msgText:gsub('\\"','"'):gsub('\\\\','\\')

				local nameFormat = format_name (name, color, alpha) 
--Couldn't figure out how to make margin of variable space length without just using for loop + array, so I just made the name invisible.
				local nameInvisible = format_name (name, color, "FF")

				FirstMargin = opt.marginwidth - string.len(name)
				if (string.len(msgText) <= FirstMargin) then
					table.insert(t,{nameFormat,msgText,msgTime})
				else	
--***this doesn't break up text if the text has no spaces, and may mess up if unicode in msg.
--					SpacePosition = string.find (msgText, " ", FirstMargin)
					SpacePosition = find_space_position (msgText, FirstMargin)
					if (SpacePosition ~= nil) then
						Msg1=msgText:sub(1,SpacePosition-1)
						table.insert(t,{nameFormat,Msg1,msgTime})
						msgText=msgText:sub(SpacePosition+1, string.len(msgText))
					end

					while (string.len(msgText) > FirstMargin) do
--						SpacePosition = string.find (msgText, " ", FirstMargin)
						SpacePosition = find_space_position (msgText, FirstMargin)
						if (SpacePosition ~= nil) then
							Msg1=msgText:sub(1,SpacePosition-1)
							table.insert(t,{nameInvisible,Msg1,msgTime})
							msgText=msgText:sub(SpacePosition+1, string.len(msgText))
						else
							table.insert(t,{nameInvisible,msgText,msgTime})						
							msgText=""
						end						
					end
					table.insert(t,{nameInvisible,msgText,msgTime})	
				end
			end
		end
	end
--	mp.msg.verbose("Got new messages. First message is: "..t[1][1]..": "..t[1][2]..", at "..t[1][3])

	return t
end

function file_loaded()
	local path = mp.get_property('path')
	local pat_twitch_vod = 'twitch.tv/videos/(%d+)'
	video_id = string.match(path, pat_twitch_vod)
	opt.font_size = opt.normal_font_size

	if video_id ~= nil then
		require 'mp.msg'
		mp.msg.verbose("I exist!")

		osd = mp.create_osd_overlay("ass-events")
		AN = 0

		current = {}
		allMsgs = pull_msgs()
		curMsg = 1

		main = mp.add_periodic_timer(0.3, function ()
		    local time = mp.get_property("time-pos")

		    if mp.get_property("core-idle") ~= "yes" and time ~= nil then

			killTime = 30
			while (tonumber(allMsgs[curMsg][3]) < tonumber(time))
			do
			    table.insert(current,allMsgs[curMsg])

			    if curMsg == table.maxn(allMsgs) then
				mp.msg.verbose("Reached end of messages. Last message was: "..allMsgs[curMsg][1]..": "..allMsgs[curMsg][2]..", at "..allMsgs[curMsg][3])

				allMsgs = pull_msgs()
				curMsg = 0
			    end

			    if killTime > 1 then
				if get_table_size(current) < 45 then
					killTime = killTime * 0.7
				else 
					print ("too much in the queue!  Shrinking Kill Time.  Queue size:", get_table_size(current))
					killTime = killTime * 0.4
				end
				mp.msg.trace("killTime: "..killTime)
			    end

			    curMsg = curMsg + 1
			end

			while (current[1] and tonumber(current[1][3])+killTime < tonumber(time))
			do
			    table.remove(current,1)
			end

			osd_refresh()
		    end
		end)

		mp.register_event("seek", reset)

		ON = true
		mp.add_key_binding("j","twitch-chat",toggle)
		mp.add_key_binding("J","enlarge-chat-fontsize",change_fontsize)
		mp.add_key_binding("9","move-chat-position-left",move_position_left)
		mp.add_key_binding("0","move-chat-position-right",move_position_right)
		mp.msg.verbose("Reached end")
	end
end

function osd_refresh()
    if (opt.font_size==opt.normal_font_size) then
	    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
				opt.posX,
				opt.posY,
				opt.font,			
				opt.font_size
			)
    else
	    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
				opt.posX/2,
				opt.posY/2,
				opt.font,			
				opt.font_size
			)
    end
    for _,v in pairs(current) do
	osd.data = osd.data..v[1].." "..format_string(v[2]).."\\N"
    end
    osd:update()
end

function reset()
    mp.msg.verbose("Reset was called")

    nxt = nil
    current = {}
    allMsgs = pull_msgs()
    curMsg = 1
end



function toggle()
 	if ON then
	    mp.osd_message("[twitch chat] off")
	    main:stop()
	    osd:remove()
	    ON = false
	    return
 	end
	mp.osd_message("[twitch chat] on")
	main:resume()
	reset()
 	ON = true

end

function move_position_left()
    print ("move_position_left()")
    opt.posX = opt.posX-20
    osd_refresh()
end

function move_position_right()
    print ("move_position_right()")
    opt.posX = opt.posX+20
    osd_refresh()
end

function change_fontsize()
    print ("increasing fontsize")
    if opt.font_size >= opt.large_font_size then
	opt.font_size = opt.normal_font_size
	osd_refresh()
    else
	opt.font_size = opt.font_size + 2
	osd_refresh()
    end
end

mp.register_event("file-loaded", file_loaded)
