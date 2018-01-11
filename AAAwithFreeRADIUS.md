Notes:
List of scenarios: https://www.strongswan.org/testing/testresults/

> Switch to VM: radius1 & radius 2

Set `Adapter 1` to `NAT network`.

> Switch to VM: radius1

```bash
sudo su
```

/etc/freeradius/clients.conf
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
"alice" Cleartext-Password := "password"
    Reply-Message = "Hello, %{User-Name}"
```

```bash
service freeradius stop

# start (in new terminal)
freeradius -X -d /etc/freeradius


# Local test
echo "User-Name=alice, User-Password=password" | radclient 127.0.0.1 auth testing123 -x
```

# Apache with radius
```bash
a2enmod auth_radius
service apache2 restart


echo "AddRadiusAuth localhost:1812 testing123 5:3" >> /etc/apache2/ports.conf
echo "AddRadiusCookieValid 1" >> /etc/apache2/ports.conf
```

/etc/apache2/sites-available/000-default.conf
```text
<Directory /var/www/html>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None

    ...
    
    # ADD THIS LINES:
    AuthType Basic
    AuthName "RADIUS Authentication for my site"
    AuthBasicProvider radius
    # Require that mod_auth_radius returns a valid user,
    # otherwise access is denied.
    Require valid-user
 
    ...   
    
</Directory>
```

```bash
service apache2 reload
freeradius -X -d /etc/freeradius

# Test
curl --user alice:password http://localhost -v
```

# Roaming and federation
By now all was on one client.

> Switch to VM: radius2
> Let $RADIUS1 and $RADIUS2 denote the IP addresses of radius1 and radius2.

> Switch to VM: radius1

/etc/freeradius/proxy.conf
```text
home_server hs_finland {
        type = auth+acct
        ipaddr = $RADIUS2
        port = 1812
        secret = testing123
}

home_server_pool pool_finland {
        type = fail-over
        home_server = hs_finland
}

realm finland {
        pool = pool_finland
        nostrip
}
```

> Switch to VM: radius2

/etc/freeradius/proxy.conf
```text
realm finland {
}
```

/etc/freeradius/clients.conf
```text
client $RADIUS1 {
    secret = testing123
}
```

We crete new supplicant (end-user).
/etc/freeradius/users
```text
"pekka" Cleartext-Password := "password"
    Reply-Message = "Hello, %{User-Name}"
```

> Switch to VM: radius1 & radius 2

```bash
freeradius -X -d /etc/freeradius
```

> Switch to VM: radius1
```bash
# Test (it should auth by radius 2)
curl --user pekka@finland:password http://localhost -v
```
