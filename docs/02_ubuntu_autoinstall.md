# Ubuntu Autoinstall Tutorial

This guide shows how to automatically install Ubuntu Server using PXE boot and the modern autoinstall method. Instead of using old netboot images, we download the official Ubuntu ISO, extract the kernel and initrd for PXE boot, and serve the full ISO and configuration files (user-data and meta-data) over HTTP. This way, we can install Ubuntu on many machines without manual steps, using a fast and reliable setup.

[tutaj diagram workflow]

## 🛠️ PXE Boot Setup for Ubuntu Autoinstall

This guide shows how to configure a PXE environment using `dnsmasq`, `pxelinux`, and `Ubuntu autoinstall`. It focuses on a legacy approach using `pxelinux.0`.

### 📡 Assign Static IPs to Worker Nodes

To simplify Ansible setup and ensure predictable SSH connectivity, it's recommended to assign **static IP addresses** to your worker nodes (e.g., via your router’s DHCP settings). This way, you can reliably list them in the Ansible `hosts` file in the next section.

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

### 🔐 Important Notes

- The username is: `ubuntu`
- The password is: `ubuntu` (hashed in the config using **SHA-512**)
- SSH is enabled, but password login is disabled (`ssh_pwauth: false`), so you must generate and use an SSH key via `ssh-keygen` command and replace existing one in `ssh_authorized_keys`.

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

### 9. Create PXELINUX Configuration Directory and Boot Menu

To control what appears when a machine boots via PXE, we need to create a PXELINUX configuration directory and define a default boot menu file inside it.

Create the directory:

```bash
sudo mkdir -p /srv/tftp/ubuntu-autoinstall/pxelinux.cfg
```

Create the default PXE menu file:

```bash
sudo vim /srv/tftp/ubuntu-autoinstall/pxelinux.cfg/default
```

Paste the following configuration into the file:

```bash
DEFAULT ubuntu-autoinstall

LABEL ubuntu-autoinstall
  KERNEL vmlinuz
  INITRD initrd
  APPEND root=/dev/ram0 ramdisk_size=1500000 autoinstall ip=dhcp cloud-config-url=http://192.168.1.27/server/user-data url=http://192.168.1.27/server/noble-live-server-amd64.iso ds=nocloud;s=http://192.168.1.27/
```

#### 🔧 Explanation of the entry

- `DEFAULT` install1: Automatically boots into the install1 option without showing a menu.

- `KERNEL` and `INITRD`: Refer to the Ubuntu kernel and initramfs files that you extracted earlier from the ISO.

- `APPEND`: Specifies boot parameters for the installer:

- `ip=dhcp`: Enables automatic IP configuration via DHCP.

- `autoinstall`: Triggers the unattended installation process.

- `cloud-config-url`: Directs the installer to download the user-data file from your HTTP server.

- `url`: Provides the location of the full ISO image.

- `ds=nocloud`: Instructs cloud-init to use the NoCloud datasource via HTTP.

#### ⚠️ Important Note

Replace all instances of `192.168.1.27` with the actual IP address of your HTTP server — the machine hosting the ISO, `user-data`, and `meta-data` files.

You can find this IP address by running:

```bash
ip a
```

### 10. Directory Structure Overview

To ensure that all PXE boot components and autoinstall files are correctly served to client machines, you should verify that the following directory structure exists on your server:

```bash
/srv/tftp/ubuntu-autoinstall/
├── pxelinux.0              # PXE bootloader binary
├── ldlinux.c32             # Required SYSLINUX module
├── vmlinuz                 # Ubuntu kernel extracted from ISO
├── initrd                  # Ubuntu initramfs extracted from ISO
└── pxelinux.cfg/
    └── default             # PXELINUX menu configuration file

/var/www/html/server/
├── noble-live-server-amd64.iso  # Official Ubuntu ISO image
├── user-data                   # Autoinstall configuration (YAML format)
└── meta-data                   # Required (can be empty) metadata file
```

- The `/srv/tftp/ubuntu-autoinstall/` directory is used by the TFTP server (via `dnsmasq`) to serve the PXE bootloader and kernel files.

- The `/var/www/html/server/` directory is served over HTTP (using `nginx`) and contains the full Ubuntu ISO and autoinstall configuration files.

Both directories must be accessible from the PXE booting client: TFTP for the initial boot and HTTP for loading the OS and configuration.

## 🧪 Test It

1. Make sure **PXE boot** is enabled in the BIOS or UEFI settings of the client machine.

2. Connect both the PXE client and the PXE/HTTP server to the **same LAN*.

3. Power on the client – it should:

    - Receive an IP address via **DHCP** from `dnsmasq`

    - Download `pxelinux.0`, `ldlinux.c32`, `vmlinuz`, and `initrd` from the **TFTP server**

    - Load and execute the PXELINUX menu from `pxelinux.cfg/default`

4. The client should **automatically boot into Ubuntu autoinstall**, fetch the ISO and configuration files over HTTP, and begin a fully unattended OS installation.

## ➡️ Continue to: Cluster Initialization and Ray Benchmarking Setup

## References

- <https://canonical-subiquity.readthedocs-hosted.com/en/latest/intro-to-autoinstall.html>
- <https://documentation.ubuntu.com/server/how-to/installation/how-to-netboot-the-server-installer-on-amd64/index.html>
- <https://c-nergy.be/blog/?p=20076>
