# PXE Boot Server Setup with dnsmasq

In this tutorial, we’ll create a PXE server that allows nodes to boot an operating system over the network. This is the foundation for fully automating node initialization in our cluster project.

## 🧠 What is PXE?

**PXE (Preboot Execution Environment)** is a standard that allows computers to boot an operating system via the network, before any OS is installed on the disk. PXE is especially useful for:

- Quickly provisioning many machines

- Avoiding the need for USB sticks or physical access

- Automating operating system installation with tools like Preseed and cloud-init

## ❓ Why `dnsmasq`?

Many consumer routers **cannot serve TFTP**, and most cannot customize PXE bootloader responses.

That’s why we run our own PXE server using dnsmasq, which combines:

- A lightweight DHCP server (assigns IP addresses to PXE clients)

- A built-in TFTP server (sends bootloader files)

- Simple configuration (perfect for isolated or offline LAN setups)

## 🗈 PXE Boot Workflow

Here’s how PXE boot works in our setup:

1. Node powers on with PXE enabled in BIOS.
2. Node sends a DHCP broadcast to request an IP.
3. dnsmasq (our PXE server) responds:
   - Assigns an IP address
   - Tells the node where to download the bootloader via TFTP
4. Node downloads bootloader (e.g., netboot.xyz)
5. Node boots into installer or live environment

![PXE boot diagram](../assets/2025-03-26-171147_hyprshot.png)

## ⚙️ Setting Up dnsmasq PXE Server

### 1. Enable PXE Boot on Target Devices

If you decided to follow this tutorial on real machines, the first step is to check whether PXE boot is enabled in the BIOS of each device. PXE boot is often referred to as **"Network Boot"** or **"Boot from LAN"** and older machines may have this setting hidden or disabled by default.

1. Reboot the machine and enter BIOS/UEFI setup (usually by pressing `Del`, `F2`, or `F12` during startup).

2. Look for settings under the **Boot**, **Advanced**, or **LAN sections**.

3. Enable options such as PXE Boot, Network Boot, or Boot from LAN.

4. Optionally, move Network Boot higher in the boot priority list.

Once enabled, save and exit the BIOS settings.

While it’s possible to set up PXE server (dnsmasq + TFTP) in an isolated container or VM, for simplicity and reliability we recommend running it directly on a bare-metal host or bridged VM where you can control the network interface easily.

### 2. Install required packages

``` bash
sudo apt update
sudo apt install dnsmasq wget syslinux-common -y
```

### 3. Prepare the TFTP Root Directory

In this step, we’ll populate the TFTP directory with the required files for PXE boot.

The key files are:

- `pxelinux.0` – The PXE bootloader from the SYSLINUX project. It’s the first file the PXE client downloads and executes. It handles showing a menu and loading the kernel.

 - `ldlinux.c32` – A required module that provides runtime support for pxelinux.0. It must be in the same directory.

- `netboot.xyz.lkrn` – A self-contained kernel provided by netboot.xyz that allows users to select and install various OSes over the network.

- `pxelinux.cfg/` – A directory where configuration files are stored. PXE clients will look here for their boot config. At minimum, a default file is needed.

#### 1. Create root and config directories for tftp

``` bash
mkdir -p /srv/tftp /srv/tftp/pxelinux.cfg
```

#### 2. Copy `pxelinux.0`, `ldlinux.c32` and download `netboot.xyz.lkrn` files

``` bash
# PXE bootloader (BIOS)
cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 /srv/tftp

# Download netboot.xyz (BIOS kernel)
wget -O /srv/tftp/netboot.xyz.lkrn https://boot.netboot.xyz/ipxe/netboot.xyz.lkrn
```

#### 3. Create PXE menu

``` bash
cat <<EOF | sudo tee /srv/tftp/pxelinux.cfg/default > /dev/null
DEFAULT netboot
LABEL netboot
MENU LABEL Boot netboot.xyz
KERNEL netboot.xyz.lkrn
EOF
```

This menu tells `pxelinux.0` to:

- Use the label `netboot` by default
- Display the option **Boot netboot.xyz**
- Load the `netboot.xyz.lkrn` kernel file when selected











## 🔁 Next Steps

Once PXE is working, we’ll move on to:

- Automating Debian installations with Preseed

- Configuring nodes using cloud-init

- Using Ansible to provision software and workloads

### ➡️ Continue to: Automated Debian Installation

