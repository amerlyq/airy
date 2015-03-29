#!/usr/bin/env python
# vim: fileencoding=utf-8

'''
gimp_wacom.py

Brendan Scott
Version: 1.20130515
15 May 2013

Copyright (C) 2013 Brendan Scott

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/


######### WHAT IT DOES
Sets mode and and ring buttons for Wacom Intuos 5 (and probably other?) tablets.
Only tested on opensuse 12.3 with Intuos5 touch m

Requires xsetwacom and libnotify-tools.  Tested on OpenSuSE 12.3.  Reimplementation of
touchring-toggle.sh by  Favux ... <favux.is <at> gmail.com>
http://article.gmane.org/gmane.linux.drivers.wacom/6703


Not much use on its own.   Must bind middle touchring button to a key sequence, and, in gimp,
bind that key sequence to this plugin.


********** Issue with LEDs
By default the LEDs on the tablet need root permisisons to set/write
so the status LED can only be changed if changes have been made when booting to
make the tablet LEDs user writable

Quoting from Favux's original script:
## To allow script to select mode status LEDs edit rc.local to change root
## only permissions on the sysfs status_led0_select file:
##   gksudo gedit /etc/rc.local
## Add the following comment and command (before 'exit 0'):
##   # Change permissions on status_led0_select file so being root isn't
##   # required to switch Wacom touch ring mode status LEDs.
##   /bin/chmod 666 /sys/bus/usb/devices/*/wacom_led/status_led0_select
##
## Intuos - status_led0_select file = the left (only) ring status LEDs.
## Cintiq - status_led1_select = the left ring; status_led0_select =
## the right ring status LEDs.  Same for the touchstrips.

For OpenSuSE:
there is presumably some way to do this so that it is set on each reboot
however, I don't know.
apparently, something to do with making a udev rule:

Make a file called /etc/udev/rules.d/wacom_permissions.sh with the following:
#!/bin/bash
/bin/chmod 666 /sys/bus/usb/devices/*/wacom_led/status_led0_select
make sure it's executable

make a file called 99-wacom-intuos.rules with the line:
ACTION=="add|change", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="056a",  RUN+="/etc/udev/rules.d/wacom_permissions.sh"

I also have ATTR{idProduct}=="0027", in my rule, but that'll only work if you have the same model
Find vendor and product ids using lsusb:
Bus 003 Device 003: ID 056a:0027 Wacom Co., Ltd Intuos5 touch M
056a is the vendor id
0027 is the product id

NB: the 99-wacom-intuos.rules don't work if the tablet is plugged in at power up
(apparently because the file system is read only until boot is completed).
Unplug and reconnect is my current workaround.
It is also possible for root to trigger a change action using udevadm from a script - perhaps on login?


#### History
Version: 1.20130515
converted to gimpplugin.plugin structure
this allows initialisation at start up to last used mode

'''

from gimpfu import *
import os
import subprocess
import gimp, gimpplugin
from gimpenums import *

HOME = os.getenv('HOME')

MODE_DIR = "%s%s"%(HOME,"/.gimp_wacom")
MODE_FILE = "%s%s"%(MODE_DIR,"/current_mode")
WACOM_SET_FMT = '''xsetwacom --set "%s" %s %s'''  # name param to

MODES = {
    "0":{"mode_msg": "Gimp Wacom: Mode 0 - Scroll up/down",
            "cmdlist":[("PAD", "AbsWheelUp","4"),  # scroll up and down
            ("PAD", "AbsWheelDown","5")]},
    "1":{"mode_msg": "Gimp Wacom: Mode 1 - increase/decrease brush size",
            "cmdlist":[("PAD", "AbsWheelUp","key alt up"),    # brush increase/decrease - must be set in gimp
            ("PAD", "AbsWheelDown","key alt down")]},
    "2":{"mode_msg": "Gimp Wacom: Mode 2 - zoom in/zoom out",
            "cmdlist":[("PAD", "AbsWheelUp"," key shift plus"),   # zoom in/out
            ("PAD", "AbsWheelDown"," key +minus -minus")]},
    "3":{"mode_msg": "Gimp Wacom: Mode 3 - next/prev layer",
            "cmdlist":[("PAD", "AbsWheelUp","key PgUp"),  # next/prev layer
            ("PAD", "AbsWheelDown","key PgDn")]}
    }
# MODES is a dict of list, with the list entries being tuples of (xsetwacom) parameters
# of the form (device key, parameter, value)
# device key is of the form "PAD", "STYLUS" etc.

DEFAULT_MODE = "0"
FIND_LED_LS = "ls /sys/bus/usb/devices/*/wacom_led/status_led0_select"
CHANGE_LED_FMT = "echo %s > %s"

def get_std_out(cmd,  shell = False):
#    print "Got command: %s"%cmd
    p = subprocess.Popen(cmd, shell = True,  stdout=subprocess.PIPE,  stderr=subprocess.PIPE)
    retval, _ = p.communicate()
    return retval

class Wacom_Device(object):
    def __init__(self):
        # get device details
        args = ["xsetwacom ","--list devices"]
        devices = get_std_out("".join(args),  shell = True)
        attached_devs =[]

        for line in devices.split('\n'):
            line = line.strip()
            if line =="":
                continue
            bits = line.split("id:")
            name = bits[0].strip()
            bits2 = bits[-1].split("type:")
            id = bits2[0].strip()
            type = bits2[-1].strip()
            add_dev = {"name":name, "id":id,"type":type}
            attached_devs.append(add_dev)

        rev_devices= {}
        for d in attached_devs:
            rev_devices[d['type']] = d['name']

        self.device_names = attached_devs
        self.name_lookup = rev_devices

        self.init_current_mode()

        # convert MODES to be specific to device we are using
        self.mode = {}
        self.mode_msg={}
        for k in MODES:
            self.mode[k] = []
            newv = []
            for list_item in MODES[k]['cmdlist']:
                tmp = []
                d = self.name_lookup[list_item[0]]
                tmp.append(d)
                tmp.append(list_item[1])
                tmp.append(list_item[2])
                newv.append(tuple(tmp))
            self.mode[k] = newv
            self.mode_msg[k] = MODES[k]["mode_msg"]
#        print self.mode

    def init_current_mode(self):
        '''Read current mode from MODE_FILE or, if none, use DEFAULT_MODE'''
        if os.path.exists(MODE_FILE):
            with open(MODE_FILE, "r") as f:
                self.current_mode = f.read()
        else:
            self.current_mode = DEFAULT_MODE

    def update_touchring(self):
        ''' set touchring by reference to self.current_mode'''
        for cmd in self.mode[self.current_mode]:
            s = get_std_out(WACOM_SET_FMT%cmd,  shell= True)

        try:
            s = get_std_out('''notify-send -t 1500 "%s"'''% self.mode_msg[self.current_mode])
            #s = get_std_out()
        except OSError as e:
            # fail silently if can't find notify-send....
            pass

        try:
            s = get_std_out(FIND_LED_LS,  shell= True)
            for p in s.split(" "): # ie for each proc location returned
                s = get_std_out(CHANGE_LED_FMT%(self.current_mode,  p))
        except OSError as e:
            print (e)
            # fail silently if can't find notify-send....
            pass


    def update_mode(self):
        '''toggle mode modulo 4 (0,1,2,3,0...)'''
        if not os.path.exists(MODE_DIR):
            spam = os.mkdir(MODE_DIR)
        if not os.path.exists(MODE_FILE):
            m = "0"  # if it doesn't exist initialise to 0
        else:
            m = str((int(self.current_mode)+1)%4)
        with open(MODE_FILE, 'w') as f:
            f. write(m)


class GimpWacom(gimpplugin.plugin):
    def start(self):
        gimp.main(self.init, self.quit, self.query, self._run)

    def init(self):
        w = Wacom_Device()
        w.update_touchring()

    def quit(self):
        pass

    def query(self):
        # called to find what functionality the plugin provides.
        gimp.install_procedure( "gimp_wacom",
              "Sets mode and buttons for Wacom Intuos 5 (and maybe other?) tablets (Linux).",
            '''Sets mode and buttons for Wacom Intuos 5 (and maybe other?) tablets.
    Requires xsetwacom and libnotify-tools.  Tested on OpenSuSE 12.3.  Reimplementation of
    touchring-toggle.sh by  Favux ... <favux.is <at> gmail.com>
    http://article.gmane.org/gmane.linux.drivers.wacom/6703
    Not much use on its own.   Must bind middle touchring button to a key sequence, and, in gimp,
    bind that key sequence to this plugin (gimp_wacom).
    ''',
            "Brendan Scott",
            "Brendan Scott",
            "2013",
            "<Image>/Tools/Wacom Touchring",
            "",
           PLUGIN,
            [(PDB_INT32, "run_mode", "Run mode")],
            [])

    def gimp_wacom(self, arg1):
        w = Wacom_Device()
        w.update_touchring()
        w.update_mode()


if __name__ == '__main__':
    GimpWacom().start()


