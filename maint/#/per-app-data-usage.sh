#!/bin/bash
# Setup network namespace with veth pair, start xterm in it
# networking - How do I connect a veth device inside an 'anonymous' network namespace to one outside? - Unix & Linux Stack Exchange ⌇⡟⡢⢢⢢
#   https://unix.stackexchange.com/questions/396175/how-do-i-connect-a-veth-device-inside-an-anonymous-network-namespace-to-one-ou/396193#396193

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

NS=${1:-ns0}
DEV=${2:-veth0}
DEV_A=${DEV}a
DEV_B=${DEV}b
ADDR=${3-:10.0.0}
ADDR_A=${ADDR}.254
ADDR_B=${ADDR}.1
MASK=${5:-24}
COL=${4:-yellow}

# echo ns=$NS dev=$DEV col=$COL mask=$MASK

ip netns add $NS
ip link add $DEV_A type veth peer name $DEV_B netns $NS
ip addr add $ADDR_A/$MASK dev $DEV_A
ip link set ${DEV}a up
ip netns exec $NS ip addr add $ADDR_B/$MASK dev $DEV_B
ip netns exec $NS ip link set ${DEV}b up
ip netns exec $NS ip route add default via $ADDR_A dev $DEV_B
ip netns exec $NS su -c "xterm -bg $COL &" your_user_id
