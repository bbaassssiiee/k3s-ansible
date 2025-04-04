airgap
=========

## Airgap Install

description: It is assumed that the control node has access to the internet. This role will automatically download the k3s install script on the control node, and then distribute all three artifacts to the managed nodes.

Requirements
------------

Airgap installation is supported via the `airgap_dir` variable. This variable should be set to the path of a directory containing the K3s binary and images. The release artifacts can be downloaded from the [K3s Releases](https://github.com/k3s-io/k3s/releases). You must download the appropriate images for you architecture (any of the compression formats will work).

Additionally, if deploying on a OS with SELinux, you will also need to download the latest [k3s-selinux RPM](https://github.com/k3s-io/k3s-selinux/releases/latest) and place it in the airgap folder.

Role Variables
--------------

$ cat inventory.yml
...
airgap_dir: ./files # Paths are relative to the playbooks directory
```

An example folder for an x86_64 cluster:
```bash
$ ls ./files/
total 248M
-rwxr-xr-x 1 $USER $USER  58M Nov 14 11:28 k3s
-rw-r--r-- 1 $USER $USER 190M Nov 14 11:30 k3s-airgap-images-amd64.tar.gz


Dependencies
------------
