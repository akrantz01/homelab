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
sudo ./bootstrap-salt.sh -P -M -N -X stable
rm bootstrap-salt.sh

# Install dependencies for git fileserver backend and AWS SSM SDB module
sudo apt-get install -y python3-pygit2 python3-pip
sudo python3 -m pip install boto3

# Configure master
mkdir -p /var/lib/salt/master

echo '127.0.0.1 salt' | sudo tee -a /etc/hosts

cat <<EOF > /etc/salt/master.d/default.conf
failhard: True
log_level: INFO
EOF
cat <<EOF > /etc/salt/master.d/engines.conf
${engines_conf}
EOF
cat <<EOF > /etc/salt/master.d/fileserver.conf
${fileserver_conf}
EOF
cat <<EOF > /etc/salt/master.d/sdb.conf
${sdb_conf}
EOF

# Set default region
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
sudo aws configure set region $REGION

# Start services
sudo systemctl restart salt-master

sleep 5

# Pull the latest version of the salt states
sudo salt-run fileserver.update
sudo salt-run saltutil.sync_all
