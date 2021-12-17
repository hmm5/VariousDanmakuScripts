--LOADS CHAT LOGS FROM RECORD DOUYU AND HUYA VIDEOS
local opt = {
	-- text styling
--	font = 'Dejavu Sans Mono Book',
	font = 'Twitter Color Emoji',
	normal_font_size = 13,
	large_font_size = 60,
	font_size = 0,
	name_font_colour = '8b8b00',
	font_colour = 'FFFFFF',
	border_size = 2.0,
	border_colour = '000000',
	alpha = '00',
	mod_font_colour = '00FF00',
	mod_border_colour = '111111',
	streamer_font_colour = '0000FF',
	streamer_border_colour = '000000',
	marginwidth = 50,
	posX = 50,
	posY = 50,
	VideoStartTime = 0,
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

function find_space_position(s, MarginSize)
	TempString = s:sub(1,MarginSize)
	TempString = string.reverse(TempString)
	SpacePosition = string.find (TempString, " ")
	if SpacePosition then
		SpacePosition = MarginSize - SpacePosition + 1
	end
	return SpacePosition
end


function wrap_text(msgText, name, msgTime, color)
	if (msgText ~= nil) then
		msgText = msgText:gsub('\\u003e','>'):gsub('\\u003c','<'):gsub('\\u0026','&')
		msgText = msgText:gsub('\\"','"'):gsub('\\\\','\\')

		local nameFormat = format_name (name, color, opt.alpha) 
--Couldn't figure out how to make margin of variable space length without just using for loop + array, so I just made the name invisible.
		local nameInvisible = format_name (name, color, "FF")

		FirstMargin = opt.marginwidth - string.len(name)
		if (string.len(msgText) <= FirstMargin) then
			table.insert(allMsgs,{nameFormat,msgText,msgTime})
		else	
--***this doesn't break up text if the text has no spaces, and may mess up if unicode in msg.
			SpacePosition = find_space_position (msgText, FirstMargin)
			if (SpacePosition ~= nil) then
				Msg1=msgText:sub(1,SpacePosition-1)
				table.insert(allMsgs,{nameFormat,Msg1,msgTime})
				msgText=msgText:sub(SpacePosition+1, string.len(msgText))
			end
			while (string.len(msgText) > FirstMargin) do
--				SpacePosition = string.find (msgText, " ", FirstMargin)
				SpacePosition = find_space_position (msgText, FirstMargin)
				if (SpacePosition ~= nil) then
					Msg1=msgText:sub(1,SpacePosition-1)
					table.insert(allMsgs,{nameInvisible,Msg1,msgTime})
					msgText=msgText:sub(SpacePosition+1, string.len(msgText))
				else
					table.insert(allMsgs,{nameInvisible,msgText,msgTime})						
					msgText=""
				end						
			end
			table.insert(allMsgs,{nameInvisible,msgText,msgTime})	
		end
	end
end


function read_subtitles(f)

    while true do
        local msgTime = f:read("*l")
        if not msgTime then
            last = f:seek()
            break
        end
        local readcolor = f:read("*l")
        if not readcolor then
--            last = f:seek()
            break
        end

        local name = f:read("*l")
        if not name then
--            last = f:seek()
            break
        end
        local msgText = f:read("*l")
        if not msgText then
--            last = f:seek()
            break
        end
        local BlankLine = f:read("*l")
        if not BlankLine then
--            last = f:seek()
            break
        end

	color = opt.name_font_colour
	if readcolor ~= "ffffff" then
		color = readcolor
	end
-- ADDING OFFSET
        msgTime = tonumber(msgTime) + opt.VideoStartTime

	if (msgTime) and (name) and (msgText) and (name ~= "Nightbot") then
--		table.insert(allMsgs,{name,msgText,msgTime})
		wrap_text(msgText, name, msgTime, color)
	end
    end
end

function file_exists(name)
	print ("NAME:  ", name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function get_table_size(tablearray)
	size = 1
	while  tablearray[size] do
	 	size = size + 1
	end
	size = size - 1
	return size
end

function file_loaded()
	opt.font_size = opt.normal_font_size
	videofilename = "null"

	if string.match (mp.get_property("media-title"), "live") then
		if string.match(mp.get_property("path"), "www.twitch.tv") then
			videofilename = string.match(mp.get_property("path"), "^https://w?w?w?%.?twitch%.tv/([^/]-)$")
			print (videofilename)
		end
		if videofilename == nil then
			videofilename = "null"
		else
			print ("LOADING TWITCH LIVE IRC CHAT")
			os.execute("sleep 16")
--			mp.commandv("run", "python3", "/home/owner/PythonTestScripts/IRCDump.py", videofilename)   
			  local args = {
				        "/home/owner/PythonTestScripts/IRCDump.py",
				        videofilename,
					    }
			mp.command_native_async({
		        name = "subprocess", 
		        capture_stdout = false, 
		        playback_only = false, 
		        args = args,
			})
		end
	end

	videotitlefilename="/tmp/" .. videofilename .. ".log"
--	Giving time for IRC Dump scrip to start executing
	os.execute("sleep 1")
	if (videotitlefilname == "null") then
		livestreamexists = false
	else
		livestreamexists = file_exists(videotitlefilename)
	end
	if livestreamexists then
--		print (logfilename)
		require 'mp.msg'
		mp.msg.verbose("I exist!")

		osd = mp.create_osd_overlay("ass-events")
		print ("video title stream filename exists!")
		f = assert(io.open(videotitlefilename,"rb"))

		opt.VideoStartTime= tonumber(mp.get_property("time-pos"))
		print ("VIDEO START TIME: ", opt.VideoStartTime)
		current = {}
		allMsgs = {}
		read_subtitles(f)
		curMsg = 1

		main = mp.add_periodic_timer(0.3, function ()
		local time = mp.get_property("time-pos")
		if mp.get_property("core-idle") ~= "yes" and time ~= nil then
			if (last < f:seek("end")) then
--				print ("THERE ARE MORE SUBS!!!!!!!!!!!!!!!!!!")
				f:seek("set", last)
				read_subtitles(f)
--				print ("GOT MORE SUBS")
			end
			killTime = 25
			while allMsgs[curMsg] and allMsgs[curMsg][3] and (tonumber(allMsgs[curMsg][3]) < tonumber(time))
			do
			    table.insert(current,allMsgs[curMsg])

			    if killTime > 1 then
				if (opt.font_size==opt.normal_font_size) then
					if get_table_size(current) < 30 then
						killTime = killTime * 0.7
					else 
						print ("too much in the queue!  Shrinking Kill Time.  Queue size:", get_table_size(current))
						killTime = killTime * 0.4
					end
				elseif (opt.font_size<=40) then
					if get_table_size(current) < 17 then
						killTime = killTime * 0.7
					else 
						print ("too much in the queue!  Shrinking Kill Time.  Queue size:", get_table_size(current))
						killTime = killTime * 0.4
					end
				else 
					if get_table_size(current) < 13 then
						killTime = killTime * 0.7
					else 
						print ("too much in the queue!  Shrinking Kill Time.  Queue size:", get_table_size(current))
						killTime = killTime * 0.4
					end
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

		mp.register_event("seek", on_seek)
		mp.register_event("shutdown", on_shutdown)
		ON = true
		mp.add_key_binding("j","chat",toggle)
		mp.add_key_binding("J","enlarge-chat-fontsize",change_fontsize)
		mp.add_key_binding("9","move-chat-position-left",move_position_left)
		mp.add_key_binding("0","move-chat-position-right",move_position_right)
		mp.add_key_binding("(","move-chat-position-up",move_position_up)
		mp.add_key_binding(")","move-chat-position-down",move_position_down)
		mp.msg.verbose("Reached end")
	end
end

function on_shutdown()
	print ("on_shutdown () QUITTING!")
--	pkillcommand = "pkill -2 -f " .. videofilename
--	print (pkillcommand)
--	os.execute(pkillcommand)   
        f:close()
	os.execute("rm "..videotitlefilename)
end

function osd_refresh()
    if (opt.font_size==opt.normal_font_size) then
	    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
				opt.posX,
				opt.posY,
				opt.font,			
				opt.font_size
			)
--    else
--	    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
--				opt.posX/4,
--				opt.posY/4,
--				opt.font,			
--				opt.font_size
--			)
    end
    for _,v in pairs(current) do
	osd.data = osd.data..v[1].." "..format_string(v[2]).."\\N"
    end
    osd:update()
end

function on_seek()
    read_subtitles(f)
    print ("on_seek:", curMsg)
    current = {}
    nxt = nil
    local pos = mp.get_property_number("time-pos")

    if pos == nil then
        curMsg = 1
        return
    end

    curMsg = 1
    while  allMsgs[curMsg] and allMsgs[curMsg][3] and (tonumber(allMsgs[curMsg][3]) < tonumber(pos)) do
		curMsg = curMsg + 1
    end

    print ("END OF on_seek:", curMsg)
end

function toggle()
 	if ON then
	    mp.osd_message("[chat] off")
	    main:stop()
	    osd:remove()
	    ON = false
	    return
 	end
	mp.osd_message("[chat] on")
	main:resume()
	on_seek()
 	ON = true

end

function change_fontsize()
    if opt.font_size >= opt.large_font_size then
	opt.font_size = opt.normal_font_size
	osd_refresh()
    else
	opt.font_size = opt.font_size + 5
	osd_refresh()
    end
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

function move_position_up()
    print ("move_position_up()")
    opt.posY = opt.posY-20
    osd_refresh()
end

function move_position_down()
    print ("move_position_down()")
    opt.posY = opt.posY+20
    osd_refresh()
end

mp.register_event("file-loaded", file_loaded)
