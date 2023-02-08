#!/usr/bin/env bash

set -euxo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

sudo systemctl stop salt-minion
sudo rm /etc/salt/pki/minion/minion_master.pub
sudo systemctl start salt-minion
