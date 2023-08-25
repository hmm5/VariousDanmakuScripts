--twitch vod chat replay plugin for mpv
local utils = require 'mp.utils'
local assdraw = require("mp.assdraw")

local opt = {
	-- text styling
--	font = 'Dejavu Sans Mono Book',
--	font = 'Noto Serif',
	font = 'Twitter Color Emoji',
	normal_font_size = 13,
	large_font_size = 60,
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
	posX = 10,
	posY = 10,
}

local settings = {
    scrolling_fontsize=45,
    ass_style = "\\1c&HC8C8B4\\bord2",
    speed = 1
}

local operation_hash = "b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a"
local client = "kimne78kx3ncx6brgo4mv6wki5h1ko"

local ban = {"Nightbot", "Moobot", "StreamElements"}
local message_format = "{\\bord1\\an1\\fs10\\alphaH33}{\\1c%s}%s: {\\1cFFFFFF}%s\\N"

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

function get_table_size(tablearray)
  size = 1
  while  tablearray[size] do
	size = size + 1
  end
  size = size - 1
  return size
end


function pull_msgs()
    local data = {
	["variables"] = {
	    ["videoID"] = video_id
	},
	["extensions"] = {
	    ["persistedQuery"] = {
		["sha256Hash"] = operation_hash
	    }
	}
    }
    if cursor ~= nil then
	data["variables"]["cursor"] = cursor
    else
	data["variables"]["contentOffsetSeconds"] = tonumber(string.match(mp.get_property("time-pos"), "^%d+"))
    end
    local res = mp.command_native{
	name = "subprocess",
	capture_stdout = true,
	args = {
	    "curl",
	    "https://gql.twitch.tv/gql",
	    "-H", "Client-ID:"..client,
	    "--data", utils.format_json(data),
	    "-s"
	}
    }
    local json = utils.parse_json(res.stdout)

    allMsgs = {}

    local b = nil
    local name = nil
    if not json or not json.data.video.comments then
--	print ("JSON comments=NIL!!!!!!!!!!!!!!!11")
	cursor = nil
	current = {}
	return allMsgs
    end
    if json ~= nil and json.data.video.comments ~= nil then
	cursor = json.data.video.comments.edges[#json.data.video.comments.edges].cursor
	for _, i in pairs(json.data.video.comments.edges) do
		b = nil
                if i.node.commenter ~= nil then
            		name = i.node.commenter.displayName
	    		b = true
	    		for _, v in pairs(ban) do
				if v == name then
				    b = false
				    break
				end
			end
                else
			b = false
		end
		if b then
			color = opt.streamer_font_colour
			if i.node.message.userColor ~= nil then
			    color = string.sub(i.node.message.userColor, 2, 7)
			end
			local msg = ""
			for _, j in pairs(i.node.message.fragments) do
			    msg = msg .. j.text
			end
			msgText=msg
			if (name) and (msgText) and (name ~= "[nightbot]") then
				msgTime=tonumber(i.node.contentOffsetSeconds)
				if (ToggleSwitch == "IRC") then			    
					wrap_text(msgText, name, msgTime, color)
				elseif (ToggleSwitch == "Scrolling") then			    
					scrolling_wrap_text(msgText, name, msgTime, color)
--					table.insert(allMsgs,{name,msgText,msgTime})
				end
			end
		end
	end
    end
--print ("!!!!!!!FUNC TABLE SIZE:", table.maxn(t))
--print ("!!!!!!!FUnC msg time:", t[1][3], "    ", mp.get_property("time-pos"))
    return allMsgs
end

function file_loaded()
	quadrant = 0
	local path = mp.get_property('path')
	local pat_twitch_vod = 'twitch.tv/videos/(%d+)'
	video_id = string.match(path, pat_twitch_vod)
	opt.font_size = settings.scrolling_fontsize
	if video_id ~= nil then
		require 'mp.msg'
		mp.msg.verbose("I exist!")

		osd = mp.create_osd_overlay("ass-events")
		AN = 0

		cursor = nil
		current = {}
		subs = {}
		
		buffer = pull_msgs()

		main = mp.add_periodic_timer(0.01, function ()
		    local t = mp.get_property("time-pos")

--		    if mp.get_property("core-idle") ~= "yes" and time ~= nil then

			killTime = 30

	    if t ~= nil then
		local time = tonumber(t)
		if mp.get_property("core-idle") ~= "yes" and time ~= nil then
		    if table.maxn(buffer) == 0 then
			buffer = pull_msgs()
		    elseif buffer[1][3] < time then
			while (buffer[1] ~= nil and buffer[1][3] < time) do
			    
			    if (ToggleSwitch == "Scrolling") then			    
					addsub (buffer[1][2])
			    else
				    table.insert(current, buffer[1])	
				    if killTime > 1 then
					if table.maxn(current) < 45 then
						killTime = killTime * 0.7
					else 
						print ("too much in the queue!  Shrinking Kill Time.  Queue size:", table.maxn(current))
						killTime = killTime * 0.4
					end
				    end
			    end
			    table.remove(buffer, 1)
			end
			osd_refresh()
		    end

		    if current[1] ~= nil and current[1][3] + killTime < time then
			while (current[1] ~= nil and current[1][3] + killTime < time) do
			    table.remove(current,1)
			end
		    end
		osd_refresh()
		end
	    end
	end)

		mp.register_event("seek", reset)
		ToggleSwitch = "IRC"
		mp.add_key_binding("j","twitch-chat",toggle)
		mp.add_key_binding("J","enlarge-chat-fontsize",change_fontsize)
		mp.add_key_binding("9","move-chat-position-left",move_position_left)
		mp.add_key_binding("0","move-chat-position-right",move_position_right)
		mp.msg.verbose("Reached end")
	end
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
					opt.posX/2,
					opt.posY/2,
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

function reset()
--print ("RESETING: PULL MSG!!!!!!!!!!!!!!!!!!!!1")
    mp.msg.verbose("Reset was called")

    cursor = nil
    current = {}
    subs = {}
    buffer = pull_msgs()
--print ("table size t:", get_table_size(allMsgs))
end



function toggle()
 	if ToggleSwitch == "IRC" then
	    mp.osd_message("[chat] Danmaku mode")
	    osd:remove()
	    ToggleSwitch = "Scrolling"
	    main:resume()
	    reset()
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
	    reset()
	    return
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

function addsub(s)
--  if s:len() > 150 then 
--    print("too long string", s)
--    return
--  end
--print("adding scrolling sub", s)
  local w, h = mp.get_osd_size()
  if not w or not h then return end
  
  if quadrant==8 then
	quadrant = 0
  end
  local sub = {}
  if table.maxn(subs) < 10 then
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
    if (sub['x']>0) then
    	total_amount_of_characters=total_amount_of_characters..sub['content']
    end
  end
  total_amount_of_characters_on_screen=string.len(total_amount_of_characters)

  for key, sub in pairs(subs) do

    local x = sub['x']
    local y = sub['y']
    local content = sub['content']
    local numberofsubs=table.maxn(subs)
    content = content

--:gsub("(>.-\\N)", "{\\1c&H35966f&}%1"):gsub("(\\N[^>])", "{\\1c&HC8C8B4}%1")

--format_string("")
    ass:new_event()
    ass:append(string.format("{\\pos(%s,%s)}%s", x, y, ass_style))
--    ass:append(string.format("{\\fs(%s)}",math.floor(h*(settings.scrolling_fontsize/1080)+0.5)))
    ass:append(content)

  custom_speed_per_content=0


  length_of_content = string.len (sub['content'])
  if length_of_content <= 25 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * .5)
--  elseif length_of_content > 100 then 
--    custom_speed_per_content = custom_speed_per_content - (settings.speed)
  end

  custom_speed_per_content = custom_speed_per_content - (settings.speed * ((length_of_content % 4)*.075))    

  if total_amount_of_characters_on_screen > 1500 then
    custom_speed_per_content = custom_speed_per_content - (settings.speed)
    if length_of_content > 250 and (numberofsubs>20) then
      custom_speed_per_content = custom_speed_per_content - (settings.speed * total_amount_of_characters_on_screen/300)
    end
  end

  if numberofsubs > 20 then 
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 1.25)
  else
    custom_speed_per_content = custom_speed_per_content - (settings.speed)
  end 

  if (total_amount_of_characters_on_screen > 300) or (numberofsubs > 50) then
    if length_of_content % 2 == 0 then custom_speed_per_content = custom_speed_per_content - (settings.speed * 1.25) end
  end

  if (sub['x'] < ((total_amount_of_characters_on_screen/1920)*w)) and (total_amount_of_characters_on_screen > 100) then
--    print ("w: ",w)  
    custom_speed_per_content = custom_speed_per_content - (settings.speed * total_amount_of_characters_on_screen/100)
  elseif (sub['x'] < ((-50/1920)*w)) then
    custom_speed_per_content = custom_speed_per_content - (settings.speed * 3)
  end

--  if (numberofsubs > 50) or ((total_amount_of_characters_on_screen > 500)) then 
--    print ("total amount of chars on screen: ", total_amount_of_characters_on_screen)
--    custom_speed_per_content = custom_speed_per_content - (settings.speed * 3)
--  end

  custom_speed_per_content=custom_speed_per_content * (h/1080)

  sub['x'] = sub['x'] + (custom_speed_per_content)


  if length_of_content <= 7 then
    if sub['x'] < -100 then table.remove(subs,key) end
  elseif numberofsubs > 50 then 
--  print ("subs table #:", get_table_size(subs))
    if sub['x'] < -200 then table.remove(subs,key) end
  elseif total_amount_of_characters_on_screen > 450 then
    if sub['x'] < -200 then table.remove(subs,key) end
  else
    if sub['x'] < -500 then table.remove(subs,key) end
  end
  end
  local w, h = mp.get_osd_size()
  mp.set_osd_ass(w, h, ass.text)

end

math.randomseed(os.time())
mp.register_event("file-loaded", file_loaded)
