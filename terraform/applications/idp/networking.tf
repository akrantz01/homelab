resource "random_integer" "subnet_index" {
  min = 0
  max = length(var.public_subnets) - 1
}

locals {
  subnet_id = var.public_subnets[random_integer.subnet_index.result]
}

resource "aws_security_group" "idp" {
  name   = "idp"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.idp.id
  type              = "ingress"

  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  cidr_blocks      = data.cloudflare_ip_ranges.public.ipv4_cidrs
  ipv6_cidr_blocks = data.cloudflare_ip_ranges.public.ipv6_cidrs
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.idp.id
  type              = "ingress"

  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks      = data.cloudflare_ip_ranges.public.ipv4_cidrs
  ipv6_cidr_blocks = data.cloudflare_ip_ranges.public.ipv6_cidrs
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.idp.id
  type              = "egress"

  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "cloudflare_dns_record" "http" {
  zone_id = data.cloudflare_zone.domain.zone_id
  name    = local.domain
  type    = "A"
  content = aws_instance.idp.public_ip

  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "https" {
  count = aws_instance.idp.ipv6_address_count

  zone_id = data.cloudflare_zone.domain.zone_id
  name    = local.domain
  type    = "AAAA"
  content = aws_instance.idp.ipv6_addresses[count.index]

  ttl     = 1
  proxied = true
}

data "cloudflare_ip_ranges" "public" {}
