# sudo apt-get install openssh-server

#VBoxManage setextradata x "VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/Protocol"  TCP
#VBoxManage setextradata x "VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/GuestPort" 22
#VBoxManage setextradata x "VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/HostPort"  2222


add_port_forward "${VNM}" "Port_ssh" "tcp,,$SIR_PORT,,22"

# 7.1.4 Remote USB
# Insert Flash-drive on one copm, use it on another!

## 8.8.2 Networking settings :
# My build server model:
#   WWW--WinHost<--NAT-ServerGuest-Intranet-->{AndroidVM, CppBuild, enc}

# NAT for www

# Intranet to communicate securily between guests w/o sniffing in real eth adapter
# See 6.6 Internal networking, needs dhcp enabled to not set static ip's manually

# Access from Host into guest by ssh 6.7 Host-only networking
# (obsolete by port-forwarding, if you need only ssh access)
#VBoxManage modifyvm "${VNM}" --nic3 hostonly

# Keeping the NAT adapter and adding a second host-only adapter works amazing
# Also, I just added additional adapter and it worked, didn't need to edit the /etc/network/interfaces

# See options:
# VBoxManage modifyvm --help  2>&1 | grep 3d

amPause
