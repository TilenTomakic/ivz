Some SSH gen. examples:
```bash
ssh-keygen -t rsa -b 4096
ssh-keygen -t dsa
ssh-keygen -t ecdsa -b 521
ssh-keygen -t ed25519
ssh-keygen -f ~/tatu-key-ecdsa -t ecdsa -b 521
```


```bash
sudo su

apt -y install openssh-server openssh-client
```


ssh-copy-id isp@$SERVER
Command `ssh-copy-id` connect to server and set-ups all, it will ask you for server password.