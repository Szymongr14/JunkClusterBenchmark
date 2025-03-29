#!/bin/bash

IFACE="enx30d0420ba6b3"
BR_DIR="/etc/netplan/01-pxe-br0.yaml"

sudo touch $BR_DIR
sudo chmod 600 $BR_DIR

sudo tee $BR_DIR << EOF > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: true
  bridges:
    pxe-br0:
      interfaces: [$IFACE]
      dhcp4: false
      parameters:
        stp: false
        forward-delay: 0
EOF

sudo netplan apply