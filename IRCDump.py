#!/usr/bin/env python3

import sys
import pathlib
import socket
import ssl
import random
import datetime
import time
import os

def main():
    channel = sys.argv[1]
    connect_and_dump_loop(channel)


def ssl_socket(server, port):
    context = ssl.create_default_context(purpose=ssl.Purpose.CLIENT_AUTH)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    context.ca_certs = None
    context.options = 0
    context.certfile = None
    context.keyfile = None
    context.ciphers = None

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ssock = context.wrap_socket(sock, do_handshake_on_connect=False)
    ssock.connect((server, port))
    return ssock


def connect_and_dump_loop(channel, server='irc.chat.twitch.tv', port=6697):
    name_postfix = ''.join([str(i) for i in random.sample(range(0, 9), 3)])
    USERNAME = f'justinfan{name_postfix}'
    PASSWORD = 'kappa'
    comments = []

    CompleteFilename=os.path.join("/tmp/", channel+".log")           
    f = open(CompleteFilename, 'w+', encoding='utf-8', buffering=1024) 


    if not channel.startswith('#'):
        channel = '#' + channel

    conn = ssl_socket(server, port)
    send_cmd(conn, 'NICK', USERNAME)
    send_cmd(conn, 'PASS', PASSWORD)
    send_cmd(conn, 'JOIN', channel)
    

    start = time.time()

    try:
        while True:
            resp = parsemsg( conn.recv(1024).decode('utf-8') )
            if not resp:
                continue
            (prefix, command, args) = resp

            if command == 'PING':
                send_cmd(conn, 'PONG', ':' + ''.join(args))
            elif command == 'PRIVMSG':
                current = round(time.time()-start, 3)+2
                name = prefix.split('!')[0]
                color = '{:06x}'.format( hash(name) % 16777216 )
                content = args[1].strip()
#                print ("Timestamp:",str(datetime.timedelta(seconds=current)).rstrip('0'), "\033[0;36;40m", name, "\033[1;37;40m", ": ", content, "\033[0m")
                L = ["{:.3f}".format(current), "\n", color, "\n", "[", name, "]", "\n", content,"\n", "\n"]			        
                f.writelines (L)
                f.flush()
    except KeyboardInterrupt:
        print ("KEYBOARD INTERRUPT RECEIVED, QUITING IRCDump")
        send_cmd(conn, "QUIT", "")
        sys.exit(0)

def send_cmd(conn, cmd, message):
    command = '{} {}\r\n'.format(cmd, message).encode('utf-8')
    print(f'>> {command}')
    conn.send(command)


# https://stackoverflow.com/a/930706
def parsemsg(s):
    prefix = ''
    trailing = []
    if not s:
        return None
    if s[0] == ':':
        prefix, s = s[1:].split(' ', 1)
    if s.find(' :') != -1:
        s, trailing = s.split(' :', 1)
        args = s.split()
        args.append(trailing)
    else:
        args = s.split()
    command = args.pop(0)
    return prefix, command, args


if __name__ == '__main__':
    main()
