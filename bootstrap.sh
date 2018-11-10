#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'This command requires a playbook name (e.g., "desktop").'
    exit 0
fi

playbook=$1

sudo apt-get update
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
ansible-playbook $playbook.yml
