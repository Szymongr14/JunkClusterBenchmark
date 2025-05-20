# Ray configuration

## Head node

Head node is a ray node which controls all worker nodes.

We run the head node on a host machine (not in the cluster).

```bash
update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
curl -sSL https://install.python-poetry.org | python3.10 -
ray stop
ray start --head --port=6379 --dashboard-host=0.0.0.0
```

## Worker node

Worker node is a ray node which does the computing.

cloud-init.yml

```yml
autoinstall:
  version: 1
  apt:
    disable_components: []
    fallback: offline-install
  identity:
    hostname: ray-worker
    username: ubuntu
    password: "$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
  package_update: false
  package_upgrade: false

  user-data:
    ssh_pwauth: false
    users:
    - name: ubuntu
      ssh_authorized_keys:
        - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIvUi/VAnbhC/QJkW9zkxA5sFtRs9HlK3gB3bt/oh8eN przyklad@test"

    package_update: true
    packages:
      - openssh-server
      - curl
      - build-essential
      - python3.10
      - python3.10-venv
      - python3.10-dev

    runcmd:
      - pip3 install --upgrade pip
      - pip3 install "ray[default]"
      - ray stop
      - ray start --address=192.168.0.24:6379

```

For each node:

### 1. Install poetry

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

### 2. Realod PATH

```bash
source ~/.profile
```

### 3. Install ray via poetry

```bash
mkdir ray_worker && cd ray_worker
poetry init --name ray_worker --no-interaction
poetry add "ray[default]"
```

### 4. Script which automatically starts ray worker after boot

```bash
#!/bin/bash

# Replace this with your head node's IP
HEAD_ADDRESS="192.168.1.10:6379"

cd /path/to/ray_worker  # Path to your minimal Poetry project
poetry run ray start --address="$HEAD_ADDRESS"
```

### 5. Create service

```bash
[Unit]
Description=Ray Worker Node
After=network.target

[Service]
Type=oneshot
RemainAfterExit=true
User=ubuntu
WorkingDirectory=/home/ubuntu/ray_worker
ExecStart=/home/ubuntu/ray_worker/start_ray_worker.sh
Restart=on-failure
Environment=PATH=/home/ubuntu/.local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
```
