Notes:
- https://wiki.strongswan.org/projects/strongswan/wiki/ConnSection
- You can also set VirtualIp by `leftsourceip`, ...
    - Example: https://www.strongswan.org/testing/testresults/ikev2/virtual-ip/index.html

> VM's:

- hq_router: NAT network, Internal `hq_subnet`
- branch_router: NAT network, Internal `branch_subnet`
- hq_server: Internal `hq_subnet`
- branch_client: Internal `branch_subnet`

On routers install:
```bash
sudo su
apt -y install strongswan ipsec-tools apache2 wireshark
usermod -a -G wireshark $USER

# Try ping between routers.
ping 10.0.2.19
```

> Switch to VM: hq_router

/etc/network/interfaces
```text
auto enp0s8
iface enp0s8 inet static
  address 10.10.0.1
  netmask 255.255.0.0
```  
```bash
service network-manager restart
ifup enp0s8
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
```

# Subnet setup
> Switch to VM: hq_server

/etc/network/interfaces
```text
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
  address 10.10.0.2
  netmask 255.255.0.0
  gateway 10.10.0.1
  dns-nameservers 8.8.8.8
```  
```bash
service network-manager restart
ifup enp0s3
```

> Switch to VM: branch_router

/etc/network/interfaces
```text
auto lo
iface lo inet loopback

auto enp0s8
iface enp0s8 inet static
  address 10.20.0.1
  netmask 255.255.0.0
```  
```bash
service network-manager restart
ifup enp0s8
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
```

> Switch to VM: branch_client

/etc/network/interfaces
```text
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
  address 10.20.0.2
  netmask 255.255.0.0
  gateway 10.20.0.1
  dns-nameservers 8.8.8.8
```  
```bash
service network-manager restart
ifup enp0s3
```

# VPN setup

> Switch to VM: hq_router

Notice: $branch_router_IP
/etc/ipsec.conf
```text
config setup

conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev2
        authby=secret

conn net-net
        leftsubnet=10.10.0.0/16
        leftfirewall=yes
        leftid=@hq
        right=$branch_router_IP
        rightsubnet=10.20.0.0/16
        rightid=@branch
        auto=add
```


Routers will be using a pre-shared key (PSK) to authenticate each other. The key is set to secret.

/etc/ipsec.secrets
```text
@hq @branch : PSK "secret"
```

```bash
ipsec restart
```

> Switch to VM: branch_router

Notice: $hq_router_IP
/etc/ipsec.conf
```text
config setup

conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev2
        authby=secret

conn net-net
        leftsubnet=10.20.0.0/16
        leftid=@branch
        leftfirewall=yes
        right=$hq_router_IP
        rightsubnet=10.10.0.0/16
        rightid=@hq
        auto=add
```

/etc/ipsec.secrets
```text
@hq @branch : PSK "secret"
```

```bash
ipsec restart

# Test
ipsec statusall
ipsec status
```
If problems stop ipsec service and run manually `sudo ipsec start --nofork`.

> Switch to VM: hq_router

```bash
ipsec up net-net
# you should get: connection 'net-net' established successfully
```
