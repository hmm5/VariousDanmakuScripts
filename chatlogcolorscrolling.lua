--LOADS CHAT LOGS FROM RECORD DOUYU AND HUYA VIDEOS
local opt = {
	-- text styling
--	font = 'Dejavu Sans Mono Book',
	font = 'Twitter Color Emoji',
	normal_font_size = 20,
	large_font_size = 60,
	font_size = 0,
	name_font_colour = '8b8b00',
	font_colour = 'FFFFFF',
	border_size = 2.0,
	border_colour = '000000',
	alpha = '40',
	mod_font_colour = '00FF00',
	mod_border_colour = '111111',
	streamer_font_colour = '0000FF',
	streamer_border_colour = '000000',
	marginwidth = 50,
	posX = 10,
	posY = 10,
}

local assdraw = require("mp.assdraw")

local settings = {
    scrolling_fontsize=45,
    ass_style = "\\1c&HC8C8B4\\bord2",
    speed = .5
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
	local w, h = mp.get_osd_size()
	local msgTextFormat = string.format(
		'{\\1c&H%s&}{\\alpha&H%s&}{\\fs%d}{\\fn%s}{\\bord%f}%s',
		opt.font_colour,
		opt.alpha,
		math.floor(h*(opt.font_size/1080)+0.5),
		opt.font,
		opt.border_size,
		message
	)
	return msgTextFormat
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

	if (msgTime) and (name) and (msgText) then
		local nameFormat = format_name (name, color, opt.alpha) 
		table.insert(allMsgs,{nameFormat,msgText,msgTime})
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
	ToggleSwitch = "IRC"
	quadrant=0
	opt.font_size = settings.scrolling_fontsize
	videofilename=mp.get_property("path")
	videotitle=mp.get_property("media-title")
	local logfilename = videofilename:match("(.+)%..+")
	if logfilename == nil then
		logfilename = "null"
	end
	local logfilename = logfilename .. ".log"

	local videotitlefilename="/tmp/" .. videotitle .. ".log"

--	print (videotitlefilename)

	livestreamexists = file_exists(videotitlefilename)
	recordlogfileexists = file_exists(logfilename)

	if livestreamexists or recordlogfileexists then
--		print (logfilename)

		require 'mp.msg'
		mp.msg.verbose("I exist!")

		osd = mp.create_osd_overlay("ass-events")
		if recordlogfileexists then		
			f = assert(io.open(logfilename,"rb"))
		else
			print ("video title stream filename exists!")
			f = assert(io.open(videotitlefilename,"rb"))
		end

		current = {}
		allMsgs = {}
		subs = {}
		read_subtitles(f)
		curMsg = 1

		main = mp.add_periodic_timer(0.005, function ()
		local time = mp.get_property("time-pos")
--		if mp.get_property("core-idle") ~= "yes" then
--				osd_refresh()
--		end
		if mp.get_property("core-idle") ~= "yes" and time ~= nil then
			if (last < f:seek("end")) then
--				print ("THERE ARE MORE SUBS!!!!!!!!!!!!!!!!!!")
				f:seek("set", last)
				read_subtitles(f)
--				print ("GOT MORE SUBS")
			end
			killTime = 30
			while allMsgs[curMsg] and allMsgs[curMsg][3] and (tonumber(allMsgs[curMsg][3]) < tonumber(time))
			do
			    if (ToggleSwitch == "Scrolling") then			    
					addsub (allMsgs[curMsg][2])
			    else
				    local w, h = mp.get_osd_size()
				    table.insert(current,allMsgs[curMsg])
				    if killTime > 1 then
					if (opt.font_size==opt.normal_font_size) then
						if get_table_size(current) < 30 then
							killTime = killTime * 0.7
						else 
							print ("too much in the queue!  Shrinking Kill Time.  Queue size:", get_table_size(current))
							killTime = killTime * 0.4
						end
					elseif (math.floor(h*(opt.font_size/1080)+0.5)<=40) then
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
	             		    while (current[1] and tonumber(current[1][3])+killTime < tonumber(time)) do 
					table.remove(current,1)
					end		
	
			     end
			     curMsg = curMsg + 1
	
			end
			osd_refresh()

		    end
		end)

		mp.register_event("seek", on_seek)
		mp.register_event("shutdown", on_shutdown)
		mp.register_event("end-file", on_shutdown)
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
	subs = {}
	current = {}
	osd:remove()
--        f:close()
end

function osd_refresh()
    if (ToggleSwitch == "IRC") then
	    local w, h = mp.get_osd_size()
	    if (opt.font_size==opt.normal_font_size) then
		    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
					opt.posX,
					opt.posY,
					opt.font,			
					math.floor(h*(opt.font_size/1080)+0.5)
				)
	    else
		    osd.data = string.format('{\\pos(%d, %d)}{\\fn%s}{\\fs%d}',
					opt.posX/4,
					opt.posY/4,
					opt.font,			
					math.floor(h*(opt.font_size/1080)+0.5)
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
    print ("on_seek:", curMsg)
    subs = {}
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
--  print("adding scrolling sub", s)
  local w, h = mp.get_osd_size()
  if not w or not h then return end
  
  if quadrant==8 then
	quadrant = 0
  end
  local sub = {}
  if get_table_size(subs) < 10 then
	sub['y'] = (math.random(1, (h/16)+(quadrant*h/8)))
  else  
	sub['y'] = (math.random((opt.font_size/1080)*h, (h/8))+(quadrant*h/8))-((opt.font_size/1080)*h)
  end
  sub['x'] = w
  sub['content'] = s:gsub("^&br!", ""):gsub("&br!", "\\N")
  table.insert(subs, sub)
  quadrant=quadrant+1

end

function render()
  local ass = assdraw.ass_new()
  ass:new_event()
  ass:append("")
  local ass_style=format_string("")
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

    content = content

--:gsub("(>.-\\N)", "{\\1c&H35966f&}%1"):gsub("(\\N[^>])", "{\\1c&HC8C8B4}%1")

--format_string("")
    ass:new_event()
    ass:append(string.format("{\\pos(%s,%s)}%s", x, y, ass_style))
--    ass:append(string.format("{\\fs(%s)}",math.floor(h*(settings.scrolling_fontsize/1080)+0.5)))
    ass:append(content)

  custom_speed_per_content=0

  length_of_content = string.len (sub['content'])
  if length_of_content/3 <= 7 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * .5)
  elseif length_of_content/3 > 25 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * .5)
  end

  custom_speed_per_content = custom_speed_per_content - (settings.speed * ((length_of_content % 4)*.075))    

  if total_amount_of_characters_on_screen/3 > 500 then
--print ("Total amount of characters on screen: ", total_amount_of_characters_on_screen/3) 
    custom_speed_per_content = custom_speed_per_content - (settings.speed*total_amount_of_characters_on_screen/300)
  end

  if get_table_size(subs) > 20 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 1.25)
--  elseif get_table_size(subs) > 30 then 
--    custom_speed_per_content = custom_speed_per_content - (settings.speed * 2.0)
  else
    custom_speed_per_content = custom_speed_per_content - (settings.speed)
  end 

  if (total_amount_of_characters_on_screen/3 > 300) or (get_table_size(subs) > 50) then
    if length_of_content % 2 == 0 then custom_speed_per_content = custom_speed_per_content - (settings.speed) end
  end

  if (sub['x'] < (((total_amount_of_characters_on_screen/3)/1920)*w)) and (total_amount_of_characters_on_screen/3 > 100) then
--  if (sub['x'] < ((600/1920)*w)) and (total_amount_of_characters_on_screen/3 > 400) then
--    print ("w: ",w)  
    custom_speed_per_content = custom_speed_per_content - (settings.speed * total_amount_of_characters_on_screen/150)
  elseif (sub['x'] < ((-50/1920)*w)) then
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 3)
  end

--  if (get_table_size(subs) > 50) or ((total_amount_of_characters_on_screen/3 > 500)) then 
--    print ("total amount of chars on screen: ", total_amount_of_characters_on_screen)
--    custom_speed_per_content = custom_speed_per_content - (settings.speed * 2)
--  end

  custom_speed_per_content=custom_speed_per_content * (h/1080)

  sub['x'] = sub['x'] + (custom_speed_per_content)


  if length_of_content/3 <= 7 then
    if sub['x'] < -100 then table.remove(subs,key) end
  elseif get_table_size(subs) > 50 then 
--  print ("subs table #:", get_table_size(subs))
    if sub['x'] < -200 then table.remove(subs,key) end
  elseif total_amount_of_characters_on_screen/3 > 450 then
    if sub['x'] < -200 then table.remove(subs,key) end
  else
    if sub['x'] < -1000 then table.remove(subs,key) end
  end
  end
  local w, h = mp.get_osd_size()
  mp.set_osd_ass(w, h, ass.text)

end

--mp.register_event("file-loaded", file_loaded)
math.randomseed(os.time())

mp.register_event("start-file", file_loaded)
