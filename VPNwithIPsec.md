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

# Extra
AES is symmetric! Both share same key.

Sample .pom files: https://we.tl/hn1nljl1YI

[Test ikev2/alg-aes-gcm: AES_GCM_16_256 ](https://www.strongswan.org/testresults4.html)
[[strongSwan] Strongswan 5.4 issue using certificates](https://lists.strongswan.org/pipermail/users/2016-August/009861.html)

DONT FORGET
> # /etc/ipsec.secrets - strongSwan IPsec secrets file
>  : RSA moonKey.pem

Create shared key:
```bash
apt -y install openssl

# ipsec pki --gen > caKey.der
# ipsec pki --self --in caKey.der --dn "C=CH, O=strongSwan, CN=strongSwan CA" --ca > caCert.der
# ipsec pki --gen > peerKey.der
# ipsec pki --pub --in peerKey.der | ipsec pki --issue --cacert caCert.der --cakey caKey.der --dn "C=CH, O=strongSwan, CN=peer" > peerCert.der
# openssl rsa -inform der -outform pem -in peerKey.der -out peerKey.pem
# cp peerKey.pem /etc/ipsec.d/certs/hqCert.pem

openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem
cp cert.pem /etc/ipsec.d/certs/hqCert.pem

# option 2
openssl req -x509 -days 730 -newkey rsa:1024 -keyout private/cakey.pem -out cacerts/moonReq.pem
openssl x509 -in /etc/ipsec.d/cacerts/moonReq.pem -out /etc/ipsec.d/certs/moonCert.pem
```

> Switch to VM: hq_router

Modify /etc/ipsec.conf
```bash
...

conn %default
	ikelifetime=60m
	keylife=20m
	rekeymargin=3m
	keyingtries=1
	keyexchange=ikev2
	ike=aes256gcm16-aesxcbc-modp2048!
	esp=aes256gcm16-modp2048!
	# note remove authby
	
conn net-net
	...
	leftcert=hqCert.pem	
	...
```


> Switch to VM: branch_router

Modify /etc/ipsec.conf
```bash
...

conn %default
	ikelifetime=60m
	keylife=20m
	rekeymargin=3m
	keyingtries=1
	keyexchange=ikev2
	ike=aes256gcm16-aesxcbc-modp2048!
	esp=aes256gcm16-modp2048!
	# note remove authby
	
conn net-net
	...
	leftcert=branchCert.pem	
	...
```

# CA
[Setting up CA .pem](https://wiki.strongswan.org/projects/strongswan/wiki/SimpleCA)

> Router VM's:
```bash
apt -y install openssl
```

```bash
mkdir vpn
cd vpn
ipsec pki --gen > caKey.der
ipsec pki --self --in caKey.der --dn "C=CH, O=strongSwan, CN=strongSwan CA" --ca > caCert.der
```

# Road W:.. with own virutal subnet

> HQ VM

/etc/ipsec.conf
10.0.2.19 is public IP of our router
```text
...
conn rw
	left=10.0.2.19
	leftid=@hq
	leftsubnet=10.10.0.0/16,10.20.0.0/16
	leftfirewall=yes
	lefthostaccess=yes
	right=%any
	rightsourceip=%config
	auto=add
...
```
NOTE IF NOT ONLY ONE:
+ add `leftsubnet=.....,10.3.0.0/16` to others
```text
conn rw
	left=10.0.2.19
	leftid=@hq
	leftsubnet=10.10.0.0/16,10.20.0.0/16
	leftfirewall=yes
	lefthostaccess=yes
	right=%any
	rightsubnet=10.3.0.0/16
	auto=add
```

> road warior VM

Notice: 10.0.2.21 is public ip of RW VM
Notice: 10.0.2.19 is public ip of ROUTER VM
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

conn home
    left=10.0.2.21
	leftsourceip=10.3.0.1
	leftid=@rw
	leftfirewall=yes
	right=10.0.2.19
	rightsubnet=10.10.0.0/16,10.20.0.0/16
	rightid=@hq
	auto=add
```

/etc/ipsec.secrets
```text
@hq @rw : PSK "secret"
```

```bash
ipsec restart
ipsec up home
```

# Virtual Ip
https://wiki.strongswan.org/issues/908
https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2Examples