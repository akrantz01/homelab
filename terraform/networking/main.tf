terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
  }
}

data "aws_availability_zones" "region" {
  state = "available"
}

locals {
  cidr = "10.0.0.0/16"
  azs  = data.aws_availability_zones.region.names
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21.0"

  name = "homelab"
  cidr = local.cidr

  enable_ipv6                                   = true
  public_subnet_assign_ipv6_address_on_creation = true

  azs = local.azs

  private_subnets              = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k)]
  private_subnet_ipv6_prefixes = [for i in range(length(local.azs)) : i]

  public_subnets              = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k + length(local.azs))]
  public_subnet_ipv6_prefixes = [for i in range(length(local.azs)) : i + length(local.azs)]

  create_igw             = true
  create_egress_only_igw = true
}
