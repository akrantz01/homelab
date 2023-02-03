#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

set -eux -o pipefail

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl ntp

sudo systemctl enable ntp
sudo systemctl start ntp

# Install salt-master
curl -o bootstrap-salt.sh -L https://bootstrap.saltproject.io
chmod +x bootstrap-salt.sh
sudo ./bootstrap-salt.sh -P -M -N stable
