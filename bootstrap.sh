#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'This command requires a playbook name (e.g., "desktop").'
    exit 0
fi

playbook=$1

if ! [ -x "$(command -v ansible-playbook)" ]; then
    echo 'Installing ansible'
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo apt-add-repository -y ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install -y ansible
fi

echo 'Running ansible playbook'
ansible-playbook $playbook.yml
