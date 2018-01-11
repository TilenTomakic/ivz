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

> Switch to VM: hq_router

```bash
ipsec up net-net
# you should get: connection 'net-net' established successfully
```
