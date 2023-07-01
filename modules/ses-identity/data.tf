data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "cloudflare_zone" "domain" {
  name = var.domain
}
