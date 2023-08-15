--LOADS CHAT LOGS FROM TWITCH
local assdraw = require("mp.assdraw")

local opt = {
	-- text styling
--	font = 'Dejavu Sans Mono Book',
	IRCDumpLocation = "/home/owner/PythonTestScripts/",
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
	posX = 10,
	posY = 10,
	VideoStartTime = 0,
}

local settings = {
    scrolling_fontsize=45,
    ass_style = "\\1c&HC8C8B4\\bord2",
    speed = .1
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

function scrolling_wrap_text(msgText, name, msgTime, color)

	wrapped_text = ""
	if (msgText ~= nil) then
		msgText = msgText:gsub('\\u003e','>'):gsub('\\u003c','<'):gsub('\\u0026','&')
		msgText = msgText:gsub('\\"','"'):gsub('\\\\','\\')

		local nameFormat = format_name (name, color, opt.alpha) 
--Couldn't figure out how to make margin of variable space length without just using for loop + array, so I just made the name invisible.
		local nameInvisible = format_name (name, color, "FF")

		FirstMargin = opt.marginwidth
		if (string.len(msgText) <= FirstMargin) then
			table.insert(allMsgs,{nameFormat,msgText,msgTime})
		else	
--***this doesn't break up text if the text has no spaces, and may mess up if unicode in msg.
			SpacePosition = find_space_position (msgText, FirstMargin)
			if (SpacePosition ~= nil) then
				Msg1=msgText:sub(1,SpacePosition-1)
				wrapped_text = wrapped_text .. Msg1 .. "\\N"
				msgText=msgText:sub(SpacePosition+1, string.len(msgText))
			end
			while (string.len(msgText) > FirstMargin) do
				SpacePosition = find_space_position (msgText, FirstMargin)
				if (SpacePosition ~= nil) then
					Msg1=msgText:sub(1,SpacePosition-1)
					wrapped_text = wrapped_text .. Msg1 .. "\\N"
					msgText=msgText:sub(SpacePosition+1, string.len(msgText))
				else
					wrapped_text = wrapped_text .. msgText .. "\\N"
					msgText=""
				end						
			end
			wrapped_text = wrapped_text .. msgText .. "\\N"
			table.insert(allMsgs,{nameInvisible,wrapped_text,msgTime})	
		end
	end
--print ("wrapped_text", wrapped_text)
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

--	msgTime = tonumber(msgTime)
	if (msgTime) and (name) and (msgText) and (name ~= "[nightbot]") then
		-- ADDING OFFSET
--		print ("bbbb", msgTime)		
--		print (tonumber(msgTime))
	        msgTime = tonumber(msgTime) + opt.VideoStartTime
		if (ToggleSwitch == "IRC") then			    
			wrap_text(msgText, name, msgTime, color)
		elseif (ToggleSwitch == "Scrolling") then			    
			scrolling_wrap_text(msgText, name, msgTime, color)
--			table.insert(allMsgs,{name,msgText,msgTime})
		end

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
		print (mp.get_property("path"))
		if string.match(mp.get_property("path"), "www.twitch.tv") then
			videofilename = string.match(mp.get_property("path"), "^https://w?w?w?%.?twitch%.tv/([^/]-)$")
			print (videofilename)
		end
		if videofilename == nil then
			videofilename = "null"
		else
			print ("LOADING TWITCH LIVE IRC CHAT")
			os.execute("sleep 16")
 
			  local args = {
				        opt.IRCDumpLocation.."IRCDump.py",
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

		opt.VideoStartTime = tonumber(mp.get_property("time-pos"))
		print ("VIDEO START TIME: ", opt.VideoStartTime)
		current = {}
		allMsgs = {}
		subs = {}
		read_subtitles(f)
		curMsg = 1

		main = mp.add_periodic_timer(0.001, function ()
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
			    if (ToggleSwitch == "Scrolling") then			    
					addsub (allMsgs[curMsg][2])
			    end

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
		ToggleSwitch = "IRC"
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
    if (ToggleSwitch == "IRC") then
	    if (opt.font_size==opt.normal_font_size) then
		    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
					opt.posX,
					opt.posY,
					opt.font,			
					opt.font_size
				)
	    else
		    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
					opt.posX/4,
					opt.posY/4,
					opt.font,			
					opt.font_size
				)
	    end
	    for _,v in pairs(current) do
		osd.data = osd.data..v[1].." "..format_string(v[2]).."\\N"
	    end
    end
    if (ToggleSwitch == "Scrolling") then
	    render()
    end     
    osd:update()
end

function on_seek()
    read_subtitles(f)
--    print ("on_seek:", curMsg)
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

--    print ("END OF on_seek:", curMsg)
end


function toggle()
 	if ToggleSwitch == "IRC" then
	    mp.osd_message("[chat] Danmaku mode")
	    ToggleSwitch = "Scrolling"
	    main:resume()
	    on_seek()
	    subs = {}
	    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
				opt.posX,
				opt.posY,
				opt.font,			
				opt.font_size
			)

	    return
	elseif ToggleSwitch == "Scrolling" then
	    subs = {}
	    render()
	    ToggleSwitch = "OFF"
	    main:stop()
	    osd:remove()
	    mp.osd_message("[chat] off")
	    return
	elseif ToggleSwitch == "OFF" then
	    subs = {}
	    mp.osd_message("[chat] IRC mode")
	    ToggleSwitch = "IRC"
   	    main:resume()
	    on_seek()
	    return
 	end
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

function addsub(s)
--  if s:len() > 150 then 
--    print("too long string", s)
--    return
--  end
--print("adding scrolling sub", s)
  local w, h = mp.get_osd_size()
  if not w or not h then return end
  local sub = {}
  if get_table_size(subs) < 5 then
	sub['y'] = math.random(15, ((h-45)/2))
  else  
	sub['y'] = math.random(15, h-45)
  end
  sub['x'] = w
  sub['content'] = s:gsub("^&br!", ""):gsub("&br!", "\\N")
--print ("s:", s)
  table.insert(subs, sub)
end

function render()
  local ass = assdraw.ass_new()
  ass:new_event()
  ass:append("")
  local w, h = mp.get_osd_size()
  total_amount_of_characters=""
  for key, sub in pairs(subs) do
    total_amount_of_characters=total_amount_of_characters..sub['content']
  end
  total_amount_of_characters_on_screen=string.len(total_amount_of_characters)

  for key, sub in pairs(subs) do

    local x = sub['x']
    local y = sub['y']
    local content = sub['content']

    content = content:gsub("(>.-\\N)", "{\\1c&H35966f&}%1"):gsub("(\\N[^>])", "{\\1c&HC8C8B4}%1")

    ass:new_event()
    ass:append(string.format("{\\pos(%s,%s)%s}", x, y, settings.ass_style))
    ass:append(string.format("{\\fs(%s)}",math.floor(h*(settings.scrolling_fontsize/1080)+0.5)))
    ass:append(content)

  custom_speed_per_content=0
  if total_amount_of_characters_on_screen > 800 then
    custom_speed_per_content = custom_speed_per_content - (settings.speed)
  end
  if get_table_size(subs) > 20 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 1.5)
  elseif get_table_size(subs) > 25 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 2.0)
  else
    custom_speed_per_content = custom_speed_per_content - (settings.speed)
  end 

  length_of_content = string.len (sub['content'])
  if length_of_content/3 <= 8 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * .5)
  elseif length_of_content > 200 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * .5)
  end
  custom_speed_per_content = custom_speed_per_content - (settings.speed * ((length_of_content % 4)*.075))    

  if (sub['x'] < -30) and (total_amount_of_characters_on_screen > 500) then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 3)
  end
  custom_speed_per_content=custom_speed_per_content * (h/1080)

  sub['x'] = sub['x'] + (custom_speed_per_content)

  if get_table_size(subs) > 25 then 
    if sub['x'] < -200 then table.remove(subs,key) end
  elseif total_amount_of_characters_on_screen > 800 then
    if sub['x'] < -200 then table.remove(subs,key) end
  else
    if sub['x'] < -2500 then table.remove(subs,key) end
  end
  end
  local w, h = mp.get_osd_size()
  mp.set_osd_ass(w, h, ass.text)

end

math.randomseed(os.time())
mp.register_event("file-loaded", file_loaded)
