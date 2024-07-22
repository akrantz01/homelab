{
  email = "alex@krantz.dev";
  server = "https://acme-v02.api.letsencrypt.org/directory";

  dnsResolver = null; # use the system resolvers

  provider = {
    name = "cloudflare";

    credentials = {
      CF_DNS_API_TOKEN_FILE = "acme/dns_api_token";
      CF_ZONE_API_TOKEN_FILE = "acme/zone_api_token";
    };
  };
}
