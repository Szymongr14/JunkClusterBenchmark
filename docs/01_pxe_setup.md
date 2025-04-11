# PXE Boot Server Setup with dnsmasq

In this tutorial, we’ll create a PXE server that allows nodes to boot an operating system over the network. This is the foundation for fully automating node initialization in our cluster project.

## 🧠 What is PXE?

**PXE (Preboot Execution Environment)** is a standard that allows computers to boot an operating system via the network, before any OS is installed on the disk. PXE is especially useful for:

- Quickly provisioning many machines

- Avoiding the need for USB sticks or physical access

- Automating operating system installation with tools like Preseed and cloud-init

## ❓ Why dnsmasq?

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


## 🔁 Next Steps

Once PXE is working, we’ll move on to:

- Automating Debian installations with Preseed

- Configuring nodes using cloud-init

- Using Ansible to provision software and workloads

### ➡️ Continue to: Automated Debian Installation

