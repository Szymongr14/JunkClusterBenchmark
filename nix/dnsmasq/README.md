# NixOS PXE VM with dnsmasq

This is a NixOS VM which has all files needed to serve PXE and netboot.xyz bootloader.
It can be run with virt-manager.

## Requirements
- bridge network interface #TODO: make tutorial for that

## Installation

Build the vm from this configuration
```bash
nix build
```

It should output the nixos.qcow (qemu image) inside result dir
T

Copy
