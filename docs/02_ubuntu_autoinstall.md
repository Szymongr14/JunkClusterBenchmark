# Zarys i komendy, zeby odtworzyc(I will create full tutorial later)

Wstep na podstawie <https://canonical-subiquity.readthedocs-hosted.com/en/latest/intro-to-autoinstall.html>

dlaczego uzywamy ubuntu netboot i autoinstall

---

For Ubuntu Server autoinstallation (since 20.04+), you typically create one YAML file that combines:

Cloud-init directives (e.g. user-data for configuring users, SSH keys, packages, etc.)

An autoinstall section inside that file for automating the actual OS installation process.

In practice, you place everything inside a single user-data file, and if you're using PXE or ISO with autoinstall, that file is passed to the installer via kernel parameters or loaded from a remote URL.

## 🛠️ PXE Boot Setup for Ubuntu Autoinstall

This guide shows how to configure a PXE environment using `dnsmasq`, `pxelinux`, and `Ubuntu autoinstall`. It focuses on a legacy approach using `pxelinux.0`.

### 1. Create TFTP Root Directory

Create the directory where TFTP files will be served from:

```bash
sudo mkdir -p /srv/tftp/ubuntu-autoinstall
```

This will act as the PXE root directory for Ubuntu boot files.

### 2. Download PXELINUX Bootloader

Fetch the pxelinux.0 bootloader from Ubuntu's legacy netboot location:

```bash
sudo wget -P /srv/tftp/ubuntu-autoinstall http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/pxelinux.0
```

📌 Note: `pxelinux.0` is the main binary used to initiate the PXE boot menu.

### 3. Add Required SYSLINUX Module

Copy ldlinux.c32, which is required for pxelinux.0 to work correctly:

```bash
sudo cp /usr/lib/syslinux/modules/bios/ldlinux.c32 /srv/tftp/ubuntu-autoinstall
```

If it doesn't exist on your system, install it via:

```bash
sudo apt install syslinux-common
```

### 4. Configure dnsmasq to Serve PXE Boot Files

Modify `tftp-root` option in `/etc/dnsmasq.d/pxe.conf` to `/srv/tftp/ubuntu-autoinstall`

After change that line in config should look like that:

```bash
tftp-root=/srv/tftp/ubuntu-autoinstall
```

Restart `dnsmasq` to apply the changes:

```bash
sudo systemctl restart dnsmasq
```

### 5. Set Up Web Server to Serve ISO + Cloud-Init Files

We’ll prepare the web server folder, download the ISO, extract the boot files, and serve everything via `Nginx`.

Create Web Server Directory:

```bash
sudo mkdir -p /var/www/html/server
cd /var/www/html/server
```

Download **Ubuntu ISO** to Web Server Directory:

```bash
wget -P /var/www/html/server http://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/noble-live-server-amd64.iso
```

Mount the ISO and Extract Kernel + Initrd:

```bash
sudo mount /var/www/html/server/noble-live-server-amd64.iso /mnt
sudo cp /mnt/casper/{vmlinuz,initrd} /srv/tftp/ubuntu-autoinstall/
sudo umount /mnt
```

`vmlinuz` and `initrd` are required by PXE to boot the Ubuntu kernel before the full system loads via HTTP.

### 6. Install and Enable Nginx Web Server

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 7. Create user-data with your autoinstall configuration

```bash
sudo vim /var/www/html/server/user-data
```

Paste the following and save the file:

```yaml
#cloud-config
autoinstall:
  version: 1
  apt:
    disable_components: []
    fallback: offline-install
  identity:
    hostname: ubuntu-server
    password: "$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
    username: ubuntu
  package_update: false
  package_upgrade: false

  user-data:
    ssh_pwauth: false
    users:
    - name: ubuntu
      ssh_authorized_keys:
        - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIvUi/VAnbhC/QJkW9zkxA5sFtRs9HlK3gB3bt/oh8eN przyklad@test"
    packages:
      - openssh-server
```

### 7. Creating the meta-data File

Ubuntu’s autoinstall process uses the cloud-init nocloud-net datasource, which expects two files:

- `user-data` – your installation configuration
- `meta-data` – even if empty, this file must exist

Create an Empty meta-data File:

```bash
sudo touch /var/www/html/server/meta-data
```

This creates an empty file in the same directory where we placed the ISO and `user-data`.

Although meta-data can be left blank, it must be present for the installer to correctly interpret the cloud-init datasource (ds=nocloud-net).

### 8. Check final /var/www/html/server directory structure

At this point, your /var/www/html/server directory must contain:

```bash
/var/www/html/server/
├── noble-live-server-amd64.iso   # Downloaded ISO file
├── user-data                     # Your autoinstall config
└── meta-data                     # Empty file, but required
```

This directory is served over HTTP and used by the installer during the PXE-based autoinstall process.


### 🔐 Important Notes

- The username is: `ubuntu`
- The password is: `ubuntu` (hashed in the config using **SHA-512**)
- SSH is enabled, but password login is disabled (`ssh_pwauth: false`), so you must generate and use an SSH key via `ssh-keygen` command and replace existing one in `ssh_authorized_keys`.

## References

- <https://canonical-subiquity.readthedocs-hosted.com/en/latest/intro-to-autoinstall.html>
- <https://documentation.ubuntu.com/server/how-to/installation/how-to-netboot-the-server-installer-on-amd64/index.html>
- <https://c-nergy.be/blog/?p=20076>
