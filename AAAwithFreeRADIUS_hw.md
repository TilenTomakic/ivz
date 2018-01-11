Based on router.md

> Switch to VM: router
```bash
sudo su

apt -y install freeradius freeradius-utils apache2 libapache2-mod-auth-radius
```

Verify: /etc/freeradius/clients.conf
```text
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    require_message_authenticator = no
    nastype = other
}
```

/etc/freeradius/users
```text
"user1" Cleartext-Password := "geslo123"
    Reply-Message = "Hello, %{User-Name}"
"roaduser" Cleartext-Password := "road"
    Reply-Message = "Hello, %{User-Name}" 
```


https://www.strongswan.org/testing/testresults/ikev2/rw-eap-md5-radius/


MD5 example:
https://www.strongswan.org/testing/testresults/ikev2/rw-eap-md5-radius/