#!/usr/bin/python
# -*- coding: utf-8 -*-
#  FileName    : HttpProxyVerifier.py
#  Author      : Fledna <fledna@ymail.com>
#  Created     : Fri Mar 11 17:31:33 2011 by fledna
#  Copyright   : Fledna Workshop (c) 2011
#  Description : Verify http proxy
#  Time-stamp: <2015-05-25 18:15:06 andelf>

import urllib2
import socket
socket.setdefaulttimeout(4.)
import logging
import re

logging.basicConfig(level=logging.INFO)
log = logging.getLogger('proxy.verifier')


def newOpener(proxy=''):
    ph = urllib2.ProxyHandler(proxy)
    opener = urllib2.build_opener(ph)
    return opener

def verifyProxyAccess(proxy,
                res_url="http://m.baidu.com/static/l.gif",
                res_size=1012):
    proxy = dict(http=proxy, https=proxy, ftp=proxy)
    try:
        opener = newOpener(proxy)
        req = opener.open(res_url)
        if len(req.read())== res_size: # trick
            return True
        else:
            return False
    except urllib2.URLError:
        return False

def verifyProxy(proxy):
    p = proxy.strip()
    log.info('Verifing %s', p)
    if verifyProxyAccess(p, "http://m.baidu.com/static/l.gif", 1012):
        log.info('http ok!')
        if verifyProxyAccess(p, "https://mail.google.com/", 234):
            log.info('https ok!')
        if verifyProxyAccess(p, "ftp://ftp.pku.edu.cn/welcome.msg", 51):
            log.info('ftp ok!')

def getProxyList():
    ret = []
    headers = {"User-Agent": 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)'}
    url = "http://proxy.ipcn.org/proxylist.html"
    req = urllib2.Request(url, headers=headers)
    html = urllib2.urlopen(req).read()
    pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)')
    ret.extend( pattern.findall(html) )
    return ret

def main():
    proxies = filter(None, getProxyList())
    for p in proxies:
        verifyProxy(p)

if __name__ == '__main__':
    main()
