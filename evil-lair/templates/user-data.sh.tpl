#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

shopt -s expand_aliases
set -eux -o pipefail

apt-get update
apt-get upgrade -y
apt-get install -y curl ntp

systemctl enable ntp
systemctl start ntp

# Install salt-master
curl -o bootstrap-salt.sh -L https://bootstrap.saltproject.io
chmod +x bootstrap-salt.sh
./bootstrap-salt.sh -P -M -N -X ${saltstack_version}
rm bootstrap-salt.sh

# Install dependencies for git fileserver backend and AWS SSM SDB module
apt-get install -y python3-pygit2 python3-pip
python3 -m pip install --upgrade pip
python3 -m pip install boto3

# Configure master
mkdir -p /var/lib/salt/master

echo '127.0.0.1 salt' >> /etc/hosts

cat <<EOF > /etc/salt/master.d/default.conf
failhard: True
log_level: INFO
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
aws configure set region $REGION

# Start services
systemctl restart salt-master

sleep 5

# Pull the latest version of the salt states
salt-run fileserver.update
salt-run saltutil.sync_all

# Install nginx and configure it to proxy to the salt-master
apt-get install -y nginx ssl-cert

cat <<EOF > /etc/nginx/sites-available/default
${nginx_default_conf}
EOF

cat <<EOF > /etc/nginx/sites-available/webhook
${nginx_webhook_conf}
EOF

ln -s /etc/nginx/sites-available/webhook /etc/nginx/sites-enabled/webhook

# Copy snakeoil certs while we wait for acme.sh
mkdir -p /etc/ssl/private /etc/ssl/certs
cp /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/${domain}.crt
cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/${domain}.key

mkdir -p /var/www/acme.sh
chown -R root:www-data /var/www/acme.sh

systemctl reload nginx

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

# Install Redis for applier
apt-get install -y redis

# Install akrantz01/applier and service
python3 -m pip install --no-warn-script-location applier==${trimprefix(applier_version, "v")}

%{ for unit in applier_downloads ~}
wget -O /usr/lib/systemd/system/${unit.name} ${unit.browser_download_url}
%{ endfor ~}

systemctl daemon-reload

%{ for unit in applier_downloads ~}
systemctl enable ${unit.name}
systemctl start ${unit.name}
%{ endfor ~}
