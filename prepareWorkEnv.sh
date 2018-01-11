#!/usr/bin/env bash

sudo su

apt update
apt -y install nano gedit curl apache2 wireshark git
usermod -a -G wireshark $USER
# sudo usermod -a -G wireshark $USER

# disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# verify that IPv6 has been disabled
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

#######################
# AAA with FreeRADIUS #
#######################




chmod +x iptables2.sh

