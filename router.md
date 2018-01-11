> Switch to VM: router

`enp0s8` cilni network, ki nima ip (ifconfig)
/etc/network/interfaces
```text
auto lo
iface lo inet loopback

auto enp0s8
iface enp0s8 inet static
  address 10.99.0.1
  netmask 255.255.0.0
  
```  
```bash
service network-manager restart
ifup enp0s8

# need to do every start up
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
iptables -A FORWARD -i enp0s8 -j ACCEPT

# test
ifconfig
```

> Switch to VM: client

/etc/network/interfaces
```text
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
  address 10.99.0.2
  netmask 255.255.0.0
  gateway 10.99.0.1
  dns-nameservers 8.8.8.8
```  
```bash
service network-manager restart
ifup enp0s3
ifconfig

# test
mtr 8.8.8.8
```