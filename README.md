# VariousDanmakuScripts

IRCDump.py is for connecting to Twitch IRC and saving Twitch live chat to a file located in /tmp/
TwitchChatLive.lua is for mpv to play IRCDumped file.
If youtube-dl is installed, simply typing in mpv "twitch url", will load up the IRCdump + TwitchChatLive.lua 

twitch-chat.lua is for playing twitch VOD recorded chat

ykdlchatbeta4 is a wrapper that runs ykdl and chatlogbeta.  If you type "ykdlchatbeta4 <a huya or douyu url>" it will begin recording both the video and logging the cat to a file
chatlogcolor.lua is used by mpv to play back the log files recorded by ykdlchatbeta4.  If "ykdlchatbeta4 -p mpv <a huya or douyu url>" is used, mpv loading chatlogcolor will look for log file in /tmp/ playing a live stream with chat
