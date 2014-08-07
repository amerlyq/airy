#!/usr/bin/env python
# coding: utf-8
import pycurl, StringIO, re

username = 'login'
password = 'pass'

def get_mail():
        data = StringIO.StringIO()
        curl = pycurl.Curl()
        curl.setopt(pycurl.WRITEFUNCTION, data.write)
        curl.setopt(pycurl.URL, 'https://'+username+':'+password+'@mail.google.com/mail/feed/atom')
        try:
                curl.perform()
        except:
                return False
        mail = re.findall('<fullcount>(.*)</fullcount>', data.getvalue())[0]
        if mail != '0': return '^fg(\#ea2121)Mail %s^fg()' % (mail)
        else: return 'Mail 0'

print get_mail()
