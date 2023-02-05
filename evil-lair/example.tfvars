# The Cloudflare API token to use, must have the following permissions: Zone.Zone, Zone.DNS
cloudflare_api_token = "your-token-here"

# The region to deploy the instance in
region = "us-west-1"

# The domain and corresponding subdomain the instance should be accessible at
domain    = "example.com"
subdomain = "salt"

# The email address to use for Let's Encrypt
letsencrypt_email = "your@email.com"

# Whether to use the Let's Encrypt staging environment
letsencrypt_staging = true

# Whether to allow SSH connectivity
enable_ssh = false
