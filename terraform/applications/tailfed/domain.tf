resource "aws_acm_certificate" "domain" {
  provider = aws.us_east_1

  domain_name       = local.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_dns_record" "certificate_verification" {
  for_each = {
    for dvo in aws_acm_certificate.domain.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.cloudflare_zone.domain.zone_id
  name    = trimsuffix(each.value.name, ".")
  content = trimsuffix(each.value.record, ".")
  type    = each.value.type

  ttl     = 1
  proxied = false
  comment = "ACM validation for tailfed custom domain"
}

resource "aws_acm_certificate_validation" "domain" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.domain.arn
  validation_record_fqdns = [for record in cloudflare_dns_record.certificate_verification : record.name]
}

resource "cloudflare_dns_record" "domain" {
  zone_id = data.cloudflare_zone.domain.zone_id
  name    = local.domain
  type    = "CNAME"
  content = module.tailfed.domain_endpoint

  ttl     = 1
  proxied = false
}

data "cloudflare_zone" "domain" {
  filter = {
    name = local.zone
  }
}
