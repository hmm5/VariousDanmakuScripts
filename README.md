# VariousDanmakuScripts
DISCLAIMER:  I am not a programmer, and somewhat amazed that these scripts I wrote up even work.  Therefore the code is ugly and hackish looking.  Hopefully though, these scripts can help someone out who wants to do something similar.  None of these scripts display on mpv in a danmaku style, but rather an IRC style. 

IRCDump.py is for connecting to Twitch IRC and saving Twitch live chat to a log file located in /tmp/

TwitchChatLive.lua is for mpv to play IRCDumped file.

If youtube-dl is installed, simply typing in mpv "twitch url", will load up the IRCdump + TwitchChatLive.lua.  In order to get TwitchChatLive.lua to work, you need to change the location in TwitchChatLive.lua

twitch-chat.lua is for playing twitch VOD recorded chat with mpv

ykdlchatbeta4 is a wrapper that runs ykdl and chatlogbeta.  If you e.g. type "ykdlchatbeta4 [a huya or douyu url]" it will begin recording both the video and logging the chat to a file.  It needs danmaku (https://github.com/THMonster/danmaku) and ykdl (https://github.com/SeaHOH/ykdl).
chatlogcolor.lua is used by mpv to play back the log files recorded by ykdlchatbeta4.  If e.g. "ykdlchatbeta4 -p mpv [a huya or douyu url]" is used, mpv loading chatlogcolor will look for log file in /tmp/ playing a live stream with chat

Thanks to https://github.com/morrah/mpv-twitch-chat-irc/ and https://codeberg.org/jouni/mpv-twitch-chat/commits/branch/master 

mpv hotkeys using lua scripts:
j - turns on and off chat
J - increases font size
9 - moves the chat position left
0 - moves the chat position right
( - moves the chat position up
) - moves the chat position down.
