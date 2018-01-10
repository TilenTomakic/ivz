
sudo su

apt -y install nano gedit curl apache2 wireshark git

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
apt -y install freeradius freeradius-utils apache2 libapache2-mod-auth-radius
