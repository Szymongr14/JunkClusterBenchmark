# steps to  (I will create full tutorial later)

```
mkdir -p /srv/tftp/ubuntu-netboot
```

```
sudo wget -P /srv/tftp/ubuntu-netboot https://releases.ubuntu.com/24.04/ubuntu-24.04.2-netboot-amd64.tar.gz
```

Modify dnsmasq config to change root to: `/srv/tftp/ubuntu-netboot/amd64`

