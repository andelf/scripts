# coding: utf8
# nc.py

print "nc.py by fledna"

import sys
import os
import socket
import getopt
import threading
import subprocess

if __name__!= '__main__':
    raise ImportError

class SocketReadThread(threading.Thread):
    """ My Socket Thread """
    def __init__(self, sock, outfp=sys.stdout):
        threading.Thread.__init__(self)
        self.sock = sock
        self.fp = sock.makefile('r')
        self.outfp = outfp
    def run(self):
        for line in self.fp:
            self.outfp.write(line)
            try:
                self.outfp.flush() # must
            except IOError, msg:
                print "[Connection Closed]"
                sys.exit(-1)

HELP_MESSAGE = \
"""
[nc.py v0.01 by fledna]
connect to somewhere:   nc [-options] hostname port[s] [ports] ...
listen for inbound:     nc -l -p port [options] [hostname] [port]
options:
\t-d          detach from console, background mode (后台模式)
\t-e prog     inbound program to exec [dangerous!!]
\t-g gateway source-routing hop point[s], up to 8
\t-G num      source-routing pointer: 4, 8, 12, ...
\t-h          this cruft (本帮助信息)
\t-i secs     delay interval for lines sent, ports scanned (延迟时间)
\t-l          listen mode, for inbound connects (监听模式,等待连接)
\t-L          listen harder, re-listen on socket close (连接关闭后,仍然继续监听)
\t-n          numeric-only IP addresses, no DNS (ip数字模式,非dns解析)
\t-o          file hex dump of traffic (十六进制模式输出文件,三段)
\t-p port     local port number (本地端口)
\t-r          randomize local and remote ports (随机本地远程端口)
\t-s addr     local source address (本地源地址)
\t-t          answer TELNET negotiation
\t-u          UDP mode
\t-v          verbose [use twice to be more verbose] (-vv 更多信息)
\t-w secs     timeout for connects and final net reads
\t-z          zero-I/O mode [used for scanning] (扫描模式,-vv)
port numbers can be individual or ranges: m-n [inclusive]
"""

verbose_level = 0
listen_mode = 0 # 0: no listen, 1: listen, 2: listen harder
TIMEOUT = socket.getdefaulttimeout()
multiple_port = False
host = ''
localaddr = ''
port = []
exec_prog = ''
proto_type = socket.SOCK_STREAM
args = sys.argv[1:]
optlist, args = getopt.getopt(args, "hde:i:lLno:p:rtuvw:z", ["help"])

for opt, val in optlist:
    if opt in ['-h', '--help']:
        print (HELP_MESSAGE)
        sys.exit(0)
    elif opt in ['-l', '-L']:
        listen_mode = 1 + int(opt=='-L')
    elif opt== '-p':
        ports = map(int, val.split('-'))
        multiple_port = len(port)!=1 # not implenmented
    elif opt== '-w':
        TIMEOUT = float(val)
    elif opt== '-e':
        exec_prog = val
    elif opt== '-v':
        verbose_level+= 1

# set host and target port
if args:
    host = args[0]
if not port:
    if len(args[1:])> 1:
        ports = map(int, args[1:])
    port = int( ports[0])

def getservbyport(port, proto='tcp'):
    try:
        return socket.getservbyport(int(port), proto)
    except:
        return "?"

if listen_mode:
    s = socket.socket(socket.AF_INET, proto_type)
    s.setblocking(True)
    s.bind((localaddr, port))
    print ("listening on [%s]:%d ..." % s.getsockname())
    s.listen(1)
    conn, addr = s.accept()
    print ("got connection to [%s]:%d from [%s]:%d" % (conn.getsockname() + conn.getpeername()))
    if exec_prog:
        p = subprocess.Popen(exec_prog, shell=True, bufsize=128,
              stdin=subprocess.PIPE, stdout=subprocess.PIPE,
              stderr=subprocess.STDOUT)
        stdin = p.stdout
        stdout = p.stdin
    else:
        stdin = sys.stdin
        stdout = sys.stdout
    t = SocketReadThread(conn, stdout)
    t.start()
    while 1:
        line = stdin.readline() # read or readline?
        if not line:
            break
        conn.send(line)
    s.close()
else: # passive connect mode GOOD
    s = socket.socket(socket.AF_INET, proto_type)
    s.setblocking(True)
    try:
        s.connect((host, port))
        print ("%s [%s]:%d (%s) open" % \
               ((host,)+s.getpeername()+ (getservbyport(port), )))
    except socket.error, msg:
        print (msg) # 10061
        sys.exit(-1)
    if exec_prog:
        p = subprocess.Popen(exec_prog, shell=True, bufsize=128,
              stdin=subprocess.PIPE, stdout=subprocess.PIPE,
              stderr=subprocess.STDOUT)
        stdin = p.stdout
        stdout = p.stdin
    else:
        stdin = sys.stdin
        stdout = sys.stdout
    t = SocketReadThread(s, stdout)
    t.start()
    while 1:
        line = stdin.readline()
        if line:
            try:
                s.send(line)
            except socket.error, msg:
                print msg
                break
        else:
            break
    s.close()
