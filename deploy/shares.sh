#!/bin/bash
# Gen: /etc/rc.local
# vim: sw=2

source ~/.bash/functions

# Add option to pre-create folders as normal user
#   (so you can create your own folders and files inside them)
#   or keep creation as sudo

# To process errors with share folder name don't exists
# You can perform mount and catch error code.
# But it's not possible for '#!/bin/sh -e' due to instant catch.

vboxshare() { wstr "
    mkdir -p /home/$CURR_USER/$1
    mount -t vboxsf $2 /home/$CURR_USER/$1"
}
ntfsshare() { wstr "
    mkdir -p /home/$CURR_USER/$1
    mount -t ntfs-3g /dev/$2 /home/$CURR_USER/$1"
}

dst=`tempfile`
wbegin_prepend "#!/bin/sh"
wstr "
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will 'exit 0' on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing."

if [ "$CURR_HOST" = "vbox" ]; then

  if [ "$CURR_PROF" = "home" ]; then
    vboxshare dld dld
    vboxshare media/hana hana
    vboxshare media/mystq mystq
    vboxshare media/umi umi
    # vboxshare media/pics Pictures
    vboxshare media/wf_erian WF_Erian
  else
    vboxshare dld Downloads
    vboxshare media Media
    vboxshare share Share
    vboxshare synchro Synchro
  fi
elif [ "$CURR_PROF" = "laptop" ]; then
    #ntfsshare sync sda6 #use wuala directly instead
    ntfsshare media sda7

    wstr "
    # For battery saving purpose. I don't use it on laptop anyway.
    ethtool -s eth0 wol d
    ifconfig eth0 down"
fi
wstr ''
wstr "exit 0"

chmod +x $dst

if ! diff -rq $dst "/etc/rc.local" ; then
    sudo mv $dst /etc/rc.local
    echo "W: ${0} - mount"
fi


