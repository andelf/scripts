#!/usr/bin/env python
# -*- coding: utf-8 -*-
#  FileName    : qqwry.py
#  Author      : <fledna@qq.com>
#  Created     : Tue Mar 29 17:33:12 2011
#  Description : QQWry python tools http://www.cz88.net/
#  Time-stamp: <2015-05-25 18:13:55 andelf>


"""
Document from http://lumaqq.linuxsir.org/article/qqwry_format_detail.html
"""

from __future__ import division
import struct
import socket


def find_record(what, fp, start, end,):
    """
    what = numberic ip, 32bit int
    fp = QQWry.dat file object, must in 'rb'
    start = record index start offset
    end  = record index end offset
    """
    def bit3_to_addr(data):
        return struct.unpack('<I', data + '\x00')[0]  # fix padding

    def get_index(start):
        fp.seek(start)
        start, sp = struct.unpack('<I3s', fp.read(7))
        sp = bit3_to_addr(sp)
        return (start, sp)

    def get_middle(start, end):
        e = (end - start) // 7
        if e <= 1:
            return start
        return start + 7 * (e // 2)

    def featch_geoinfo(one_more=True):
        mode = fp.read(1)
        if mode == '\x01':
            off = bit3_to_addr(fp.read(3))
            fp.seek(off)
            return featch_geoinfo(one_more)
        elif mode == '\x02':
            off = bit3_to_addr(fp.read(3))
            current = fp.tell()
            fp.seek(off)
            if one_more:
                ret = featch_geoinfo(False)
                fp.seek(current)
                return ret + featch_geoinfo(False)
            return featch_geoinfo(False)
        elif mode == '\x00':
            return u'未知'
        else:                           # normal
            ret = [mode]
            while True:
                c = fp.read(1)
                if c == '\x00':
                    ret = ''.join(ret)
                    break
                ret.append(c)
            ret = ''.join(ret)
            ret = unicode(ret, 'gbk', 'ignore')
            if one_more:
                return ret + featch_geoinfo(False)
            return ret

    def get_record(offset):
        if offset:
            fp.seek(offset)
            ip = fp.read(4)             # FIXME: ip should return
            return featch_geoinfo()
        else:
            return u'未知'

    middle = get_middle(start, end)    # initial
    while middle != start:
        start_ip, sp = get_index(start)
        end_ip, _ = get_index(end)
        middle_ip, _ = get_index(middle)

        if what >= end_ip:
            start = end
        elif what <= start_ip:
            end = start
        elif start_ip <= what <= middle_ip:
            end = middle
        elif middle_ip <= what <= end_ip:
            start = middle
        else:
            raise RuntimeError('sucks')
        middle = get_middle(start, end)

    return get_record(sp)


def is_ipv4_address(addr):
    """
    Determine whether the given string represents an IPv4 address.
    Code from twisted project.
    """
    dottedParts = addr.split('.')
    if len(dottedParts) == 4:
        for octet in dottedParts:
            try:
                value = int(octet)
            except ValueError:
                return False
            else:
                if value < 0 or value > 255:
                    return False
        return True
    return False


def get_ips_by_name(name):
    addrs = socket.getaddrinfo(name, None, socket.AF_INET)
    return [addr[4][0] for addr in addrs]


def query_ip(ip):
    if isinstance(ip, (str, unicode)):
        ip = socket.inet_aton(ip)
        ip = struct.unpack('>I', ip)[0]

    with open('QQWry.dat', 'rb') as fp:
        first = fp.read(4)
        end = fp.read(4)
        first = struct.unpack('<I', first)[0]
        end = struct.unpack('<I', end)[0]
        return find_record(ip, fp, first, end)


def query_name(name):
    if isinstance(name, (str, unicode)):
        if not is_ipv4_address(name):
            ips = get_ips_by_name(name)
        else:
            ips = [name]
    for ip in ips:
        print ip, '\t',
        print query_ip(ip)


def main():
    """main func"""
    import sys
    name = sys.argv[1]
    query_name(name)


if __name__ == '__main__':
    main()
