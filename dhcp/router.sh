#!/bin/sh

# Commands to system binaries
IFCONFIG=/sbin/ifconfig
IPCALC=/usr/bin/ipcalc

# If we didnt get a CLI argument of the interface, die
#if [[ $1 == "" ]]; then
if [[ $#<1 ]]; then
	echo "Usage: ./route.sh [interface]" >&2
	exit 1
fi

# Set some variables
INTERFACE=$1
IPADDR=`$IFCONFIG $INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
IPMASK=`$IFCONFIG $INTERFACE | grep 'inet addr:' | cut -d: -f4 | awk '{ print $1}'`
GWADDR=`$IPCALC $IPADDR $IPMASK | grep HostMax | cut -d: -f 2 | awk '{ print $1 }'`
NETWORK=`$IPCALC $IPADDR | grep Network | cut -d: -f 2 | awk '{print $1}'`
TABLE="$INTERFACE-T"

# Shit some bricks
echo "INTERFACE: $INTERFACE"
echo "LOCAL IP: $IPADDR"
echo "LOCAL MASK: $IPMASK"
echo "GATEWAY IP: $GWADDR"
echo "NETWORK: $NETWORK"

# Route commands
echo "ip route add $NETWORK dev $INTERFACE src $IPADDR table $TABLE"
echo "ip route add default via $GWADDR table $TABLE"
echo "ip route add $NETWORK dev $INTERFACE src $IPADDR"
echo "ip rule add from $IPADDR table $TABLE"
