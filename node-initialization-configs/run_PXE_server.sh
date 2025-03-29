#!/bin/bash

CONTAINER_NAME="pxe-server"
DEVICE_NAME="eth0"
IFACE="enx30d0420ba6b3"

# Check if LXD is installed
if ! command -v lxd >/dev/null 2>&1; then
  echo "LXD is not installed. Please install it and try again."
  exit 1
fi

# Delete container if it exists
if sudo lxc info $CONTAINER_NAME >/dev/null 2>&1; then
  sudo lxc delete $CONTAINER_NAME -f
fi

# Launch container (don't start yet)
sudo lxc init ubuntu:22.04 $CONTAINER_NAME

# Attach configs
sudo lxc config set $CONTAINER_NAME user.user-data - < cloud-init.yaml
sudo lxc config set $CONTAINER_NAME security.nesting true
sudo lxc config set $CONTAINER_NAME security.privileged true

# Add macvlan NIC
sudo lxc config device add $CONTAINER_NAME $DEVICE_NAME nic \
  nictype=macvlan \
  parent=$IFACE \
  name=eth0

# Start the container
sudo lxc start $CONTAINER_NAME

sudo lxc shell $CONTAINER_NAME

