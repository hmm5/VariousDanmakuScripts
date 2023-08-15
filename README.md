# VariousDanmakuScripts
These scripts are used to display various streaming site (twitch, huya, douyu) chat on mpv or record chat and video to a file to be viewed later.

DISCLAIMER:  I am not a programmer, and have never before written anything using python or lua and somewhat amazed that these scripts I wrote up even work.  Therefore the code is ugly and hackish looking and there are probably much better ways of doing things.  Hopefully though, these scripts can help someone out who wants to do something similar.   These scripts as far as I know work only with linux, but if someone wants to edit them to work with windows, it shouldn't be too difficult.  I don't have a windows computer to test them on, and so don't know what would be needed to get them working.  

IRCDump.py is for connecting to Twitch IRC and saving Twitch live broadcast chat to a log file located in /tmp/

TwitchChatLive.lua is for mpv to play IRCDumped file using mpv, e.g. "mpv https://www.twitch.tv/macaw45", will automatically load mpv and try to load IRCDump.py to display chat during a live broadcast if yt-dlp is also installed. In order to get TwitchChatLive.lua to work, you need to change the file location of IRCDump.py in TwitchChatLive.lua

twitch-chat.lua is for playing twitch VOD recorded chat with mpv

ykdlchatbeta5 is a wrapper that runs ykdl and chatlogbeta.  If you e.g. type "ykdlchatbeta5 [a huya or douyu url]" it will begin recording both the video and logging the chat to a file.  It needs danmaku (https://github.com/THMonster/danmaku) and ykdl (https://github.com/SeaHOH/ykdl).
chatlogcolor.lua is used by mpv to play back the log files recorded by ykdlchatbeta5.  If e.g. "ykdlchatbeta5 -p mpv [a huya or douyu url]" is used, mpv loading chatlogcolor will look for a log file in /tmp/, playing a live stream with chat.  chatlogbeta.py is used to record the logs.

Thanks to https://github.com/morrah/mpv-twitch-chat-irc/ and https://codeberg.org/jouni/mpv-twitch-chat/commits/branch/master 

mpv hotkeys using lua scripts:
j - turns on and off as well as swtiches between IRC line mode versus danmuku scrolling mode chat
J - increases font size
9 - moves the chat position left
0 - moves the chat position right
( - moves the chat position up
) - moves the chat position down.

lua scripts should be placed in ~/.config/mpv/scripts
