#!/bin/bash
# Just `source ./k3s-wsl.sh`
deactivate > /dev/null 2>&1
rm -rf .venv
python3.12 -m venv .venv
# shellcheck source=/dev/null
source .venv/bin/activate
pip install --upgrade pip wheel
pip install -r requirements.txt
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
./site.yml
deactivate > /dev/null 2>&1
