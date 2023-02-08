#!/usr/bin/env bash

###
### Onboards a server as a SaltStack Minion
###

# Ensure the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Check the required arguments are present
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <salt-master> <minion-id>"
    exit 1
fi

SALT_MASTER=$1
MINION_ID=$2

set -euxo pipefail

# Update the system and install the required packages
source /etc/os-release
case "$ID" in
    ubuntu|debian)
        apt-get update
        apt-get upgrade -y
        apt-get install -y curl ntp
        ;;
    *)
        echo "Unsupported OS: $ID"
        exit 1
        ;;
esac

# Install SaltStack
curl -o bootstrap-salt.sh -L https://bootstrap.saltproject.io
chmod +x bootstrap-salt.sh
./bootstrap-salt.sh -P -A $SALT_MASTER -i $MINION_ID stable
