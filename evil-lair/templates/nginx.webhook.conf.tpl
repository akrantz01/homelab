upstream applier {
    server unix:/run/applier.sock;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    ssl_certificate /etc/ssl/certs/${domain}.crt;
    ssl_certificate_key /etc/ssl/private/${domain}.key;

    server_name ${domain};

    location / {
        proxy_pass http://applier;
        proxy_redirect off;
        proxy_buffering off;

        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
