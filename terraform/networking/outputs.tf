output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "The public subnet IDs"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "The private subnet IDs"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID"
}
