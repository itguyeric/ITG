# ITG Infrastructure Automation

This repo contains Ansible playbooks and roles for provisioning and configuring virtual machines on **ITG02** (Dell R730 running AlmaLinux 10.0 with libvirt).

## Features

- Provision VMs from cloud images (Fedora, Alma, etc.)
- Configure bridged networking
- Inject SSH keys and optional Tailscale setup
- Thin-provisioned qcow2 storage
- Cloud-init and Ansible role-based customization
- Designed to replace legacy Unraid workflows

## Getting Started

Clone this repo on your development machine (e.g., `Friday`), then:

```bash
# Create a Python virtual environment (optional but recommended)
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt  # (once created)

# Run a provisioning playbook
ansible-playbook -i inventories/itg02 playbooks/provision.yml
