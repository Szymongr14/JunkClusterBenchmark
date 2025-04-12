# Zarys i komendy, zeby odtworzyc(I will create full tutorial later)

Wstep na podstawie <https://canonical-subiquity.readthedocs-hosted.com/en/latest/intro-to-autoinstall.html>

dlaczego uzywamy ubuntu netboot i autoinstall

---

For Ubuntu Server autoinstallation (since 20.04+), you typically create one YAML file that combines:

Cloud-init directives (e.g. user-data for configuring users, SSH keys, packages, etc.)

An autoinstall section inside that file for automating the actual OS installation process.

In practice, you place everything inside a single user-data file, and if you're using PXE or ISO with autoinstall, that file is passed to the installer via kernel parameters or loaded from a remote URL.



## Steps in that tutorial
--- 
```
mkdir -p /srv/tftp/ubuntu-netboot
```

```
sudo wget -P /srv/tftp/ubuntu-netboot https://releases.ubuntu.com/24.04/ubuntu-24.04.2-netboot-amd64.tar.gz
```

Modify dnsmasq config to change root to: `/srv/tftp/ubuntu-netboot/amd64`

```
sudo mkdir -p /var/www/html/ubuntu-autoinstall
cd /var/www/html/ubuntu-autoinstall
```

## References

- <https://canonical-subiquity.readthedocs-hosted.com/en/latest/intro-to-autoinstall.html>