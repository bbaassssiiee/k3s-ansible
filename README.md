# Build a Kubernetes cluster using K3s via Ansible

Author: <https://github.com/itwars>
Current Maintainer: <https://github.com/bbaassssiiee>

Easily bring up a cluster on machines running:

- [X] Debian
- [X] Ubuntu
- [X] Raspberry Pi OS
- [X] RHEL Family (CentOS, Redhat, Rocky Linux...)
- [X] SUSE Family (SLES, OpenSUSE Leap, Tumbleweed...)
- [X] ArchLinux

on processor architectures:

- [X] x64
- [X] arm64
- [X] armhf

## System requirements

The control node **must** have ansible-core 2.16

All managed nodes in inventory must have:
- Passwordless SSH access
- Root access (or a user with equivalent permissions)

It is also recommended that all managed nodes disable firewalls and swap. See [K3s Requirements](https://docs.k3s.io/installation/requirements) for more information.

## Installation

On WSL (tested on AlmaLinux) just `source k3s-wsl.sh` from this repo.

### With ansible-galaxy

`bbaassssiiee.k3s` is a Ansible collection and can be installed with the `ansible-galaxy` command:

```console
$ ansible-galaxy collection install git+https://github.com/bbaassssiiee/k3s-ansible.git
```

### From source

Alternatively to an installation with `ansible-galaxy`, the `k3s-ansible` repository can simply be cloned from Azure DevOps:

```console
$ git clone https://github.com/bbaassssiiee/k3s-ansible.git
$ cd k3s-ansible
```

## Usage


With one `k3s_server` it is sufficient to edit your `~/.ssh/config` file having values similar to:

```text
Host k3s_server
    Hostname 192.168.10.10
    User cluster_admin
    ForwardAgent yes
    LocalForward 6443 127.0.0.1:6443
    StrictHostKeyChecking yes
    CheckHostIP yes
    IdentityFile ~/.ssh/id_ed25519
```

Alternatively edit the inventory/cloud/hosts match your cluster setup. For example:

```ini
[k3s_cluster:children]
server
agent

[server]
k3s_s10 ansible_host=192.168.10.10

[agent]
ks3_a21 ansible_host=192.168.10.21
ks3_a22 ansible_host=192.168.10.22

[k3s_cluster:vars]
airgap_dir=files
```

If needed, you can also add to `vars` section at the bottom to match your environment.

If multiple hosts are in the server group the playbook will automatically setup k3s in HA mode with embedded etcd.
An odd number of server nodes is required (3,5,7). Read the [official documentation](https://docs.k3s.io/datastore/ha-embedded) for more information.

Setting up a loadbalancer or VIP beforehand to use as the API endpoint is possible but not covered here.

Start provisioning of the cluster using one of the following commands. The command to be used depends on whether you installed `k3s-ansible` with `ansible-galaxy` or if you run the playbook from within the cloned git repository:

*Installed with ansible-galaxy*

```yaml
#!/usr/bin/env ansible-playbook
---
- name: Synchronization
  hosts: localhost
  become: false
  tags: [sync]
  vars:
    debug: true
  roles:
    - role: bbaassssiiee.k3s.sync

- name: Cluster prep
  hosts: k3s_cluster
  gather_facts: true
  become: true
  tags: [prep]
  roles:
    - role: bbaassssiiee.k3s.prereq
    - role: bbaassssiiee.k3s.airgap
    - role: bbaassssiiee.k3s.k3s_custom_registries
      when: registry_host is defined

- name: Setup K3S server
  hosts: server
  become: false
  tags: [server]
  roles:
    - role: bbaassssiiee.k3s.k3s_server

- name: Setup K3S agent
  hosts: agent
  become: false
  tags: [agent]
  roles:
    - role: bbaassssiiee.k3s.k3s_agent
```

*Running the playbook from inside the repository*

```bash
./site.yml -K -vv
```

### Using an external database

If an external database is preferred, this can be achieved by passing the `--datastore-endpoint` as an extra server argument as well as setting the `use_external_database` flag to true.

```bash
k3s_cluster:
  children:
    server:
      hosts:
        192.16.35.11:
        192.16.35.12:
    agent:
      hosts:
        192.16.35.13:

  vars:
    use_external_database: true
    extra_server_args: "--datastore-endpoint=postgres://username:password@hostname:port/database-name"
```

The `use_external_database` flag is required when more than one server is defined, as otherwise an embedded etcd cluster will be created instead.

The format of the datastore-endpoint parameter is dependent upon the datastore backend, please visit the [K3s datastore endpoint format](https://docs.k3s.io/datastore#datastore-endpoint-format-and-functionality) for details on the format and supported datastores.

## Upgrading

A playbook is provided to upgrade K3s on all nodes in the cluster. To use it, update `k3s_version` with the desired version in `inventory.yml` and run one of the following commands. Again, the syntax is slightly different depending on whether you installed `bbaassssiiee.k3s` with `ansible-galaxy` or if you run the playbook from within the cloned git repository:


*Installed with ansible-galaxy*

```bash
ansible-playbook bbaassssiiee.k3s.upgrade -i your_inventory
```

*Running the playbook from inside the repository*

```bash
ansible-playbook upgrade.yml
```

## Airgap Install

Airgap installation is supported via the `airgap_dir` variable. This variable should be set to the path of a directory containing the K3s binary and images. The release artifacts can be downloaded from the [K3s Releases](https://github.com/k3s-io/k3s/releases). The `sync` role will download the appropriate images for you if the airgap_dir var is defined (default).

An example folder for an x86_64 cluster:
```bash
$ ls -lh ./files/
total 272M
-rw-r--r-- 1 nobody nobody  68M Apr  2 15:26 k3s
-rw-r--r-- 1 nobody nobody 169M Apr  2 15:26 k3s-airgap-images-amd64.tar.gz
-rwxr-xr-x 1 nobody nobody  36K Apr  2 15:26 k3s-install.sh
-rw-r--r-- 1 nobody nobody  21K Apr  2 15:26 k3s-selinux-1.6-1.el8.noarch.rpm
-rw-r--r-- 1 nobody nobody  35M Apr  2 15:26 k9s_Linux_amd64.tar.gz

Additionally, for deploying on a OS with SELinux, sync will download the latest [k3s-selinux RPM](https://github.com/k3s-io/k3s-selinux/releases/latest) and place it in the airgap folder.

It is assumed that the control node has access to the internet. The playbook will automatically download the k3s install script on the control node, and then distribute all three artifacts to the managed nodes.

## Kubeconfig

After successful bringup, the kubeconfig of the cluster is copied to the control node  and merged with `~/.kube/config` under the `bbaassssiiee.k3s` context.

Use [k9s](https://k9scli.io/topics/commands/) as the commander to manage your K3s cluster.

```bash
k9s
```

If you wish for your kubeconfig to be copied elsewhere and not merged, you can set the `kubeconfig` variable in `inventory.yml` to the desired path.

## Need More Features?

This project is intended to provide a "vanilla" K3s install. If you need more features, such as:
- Private Registry
- Advanced Storage (Longhorn, Ceph, etc)
- External Database
- External Load Balancer or VIP
- Alternative CNIs

See these other projects:
- https://github.com/bbaassssiiee/k3s-ansible
- https://github.com/PyratLabs/ansible-role-k3s
- https://github.com/techno-tim/k3s-ansible
- https://github.com/jon-stumpf/k3s-ansible
- https://github.com/alexellis/k3sup
- https://github.com/axivo/k3s-cluster
