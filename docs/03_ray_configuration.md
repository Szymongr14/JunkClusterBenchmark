# ⚙️ Setting Up Ray Worker Nodes with Ansible

Once your worker machines are automatically provisioned via **Ubuntu autoinstall**, they are accessible via SSH from the head machine. This enables you to configure them remotely using Ansible.

We’ll now:

1. Install Ray and dependencies on all worker nodes

2. Start Ray worker processes

3. Later, stop them cleanly when needed

## 🔧 Prerequisites

- **Install Ansible on the Head Machine:** [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html)
- **Update the Ansible Inventory File**
  Add the IP addresses of your worker nodes under the ray_worker_nodes group in the `ansible/hosts` file:

  ### Example `hosts`

  ```bash
  [ray_worker_nodes]
  192.168.0.101
  192.168.0.102
  192.168.0.103
  ```

## 📂 Ansible Project Structure

Directory with Ansible configuration files in our project looks like that

```markdown
ansible/
├── ansible.cfg
├── hosts
├── group_vars/
│   ├── ray_worker_nodes.yaml
├── playbooks/
│   ├── prepare_worker_nodes.yaml
│   ├── start_ray_on_worker_nodes.yaml
│   └── stop_ray_on_worker_nodes.yaml
└── roles/
    └── ray/
        ├── files/
        │   ├── pyproject.toml
        └── tasks/
            ├── copy_poetry_configuration_files.yaml
            ├── install_poetry.yaml
            ├── prepare_scp.yaml
            ├── start_ray_on_worker_nodes.yaml
            └── stop_ray_on_worker_nodes.yaml
```

Each playbook in the playbooks/ directory corresponds to a major automation task.

## Run Ray Head Node Locally (On Head Machine)

You don’t need Ansible to start the Ray head — use Poetry locally:

### 1. Initialize a Python project

```bash
poetry init
```

(Just press enter for default prompts.)

### Install Ray 

```bash
poetry add ray
```

### Start the Ray Head

```bash
poetry run ray start --head --port=6379
```

You should see something like:

```bash
Local node IP: 192.168.1.10
Ray runtime started.
```

Copy the IP — your workers will connect to it automatically using Ansible.

➡️ Now that you know the head IP, update it in your Ansible variables by editing: `ansible/group_vars/ray_worker_nodes.yaml` file.

Example:

```yaml
ray_head_address: 192.168.1.10:6379
```

This will be used by Ansible to start Ray on each worker and connect it to the head node.

## Step-by-Step Commands to run Ray on worker nodes

### 1. Prepare All Worker Nodes

This will install Poetry, Ray, and copy necessary scripts:

```bash
ansible-playbook playbooks/prepare_worker_nodes.yaml --ask-become-pass
```

### 2. Start Ray Worker Processes

This connects workers to the Ray head:

```bash
ansible-playbook playbooks/start_ray_on_worker_nodes.yaml --ask-become-pass
```

### 3. Stop Ray Worker Processes (when needed)

Cleanly stop Ray workers:

```bash
ansible-playbook playbooks/stop_ray_on_worker_nodes.yaml --ask-become-pass
```

## ✅ Summary

- We used **Ubuntu autoinstall** to provision all nodes and enable SSH

- Then we used **Ansible** to automate Ray setup and lifecycle on each worker

- We started the **Ray head locally** using Poetry

## ➡️ Next: We'll benchmark the cluster and run distributed jobs to evaluate performance
