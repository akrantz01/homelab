#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

shopt -s expand_aliases
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

# Install nginx and configure it to proxy to the salt-master
sudo apt-get install -y nginx ssl-cert

cat <<EOF > /etc/nginx/sites-available/default
${nginx_default_conf}
EOF

cat <<EOF > /etc/nginx/sites-available/webhook
${nginx_webhook_conf}
EOF

sudo ln -s /etc/nginx/sites-available/webhook /etc/nginx/sites-enabled/webhook

# Copy snakeoil certs while we wait for acme.sh
sudo mkdir -p /etc/ssl/private /etc/ssl/certs
sudo cp /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/${domain}.crt
sudo cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/${domain}.key

sudo mkdir -p /var/www/acme.sh
sudo chown -R root:www-data /var/www/acme.sh

sudo systemctl reload nginx

# Setup TLS with Let's Encrypt (via acme.sh)
curl https://get.acme.sh | sh -s email="${letsencrypt_email}"
source /.acme.sh/acme.sh.env

acme.sh --issue \
    --webroot /var/www/acme.sh \
    --server "${letsencrypt_server}" \
    --domain "${domain}"

acme.sh --install-cert \
    --domain "${domain}" \
    --reloadcmd "systemctl reload nginx" \
    --key-file /etc/ssl/private/${domain}.key \
    --fullchain-file /etc/ssl/certs/${domain}.crt
