data "cloudflare_zone" "zone" {
  name = var.domain
}

resource "cloudflare_record" "ipv4" {
  zone_id = data.cloudflare_zone.zone.id

  type  = "A"
  name  = var.subdomain
  value = aws_instance.evil_lair.public_ip

  proxied = false
}

resource "cloudflare_record" "ipv6" {
  zone_id = data.cloudflare_zone.zone.id

  type  = "AAAA"
  name  = var.subdomain
  value = aws_instance.evil_lair.ipv6_addresses[0]

  proxied = false
}
