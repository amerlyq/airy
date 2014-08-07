#!/usr/bin/env python
# coding: utf-8
from subprocess import Popen, PIPE

status = {'Dropbox isn\'t running!': '^fg(\#ea2121)Off^fg()',
        '/home/user/Dropbox: up to date': 'On',
        '/home/user/Dropbox: syncing': '^fg(\#87ff73)Sync^fg()'}

def get_status():
        pp = Popen('dropbox filestatus /home/user/Dropbox', shell=True, stdout=PIPE).stdout.read().replace('\n', '')
        return status[pp]

print get_status()
