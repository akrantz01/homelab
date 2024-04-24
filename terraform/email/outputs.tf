output "krantz_cloud" {
  value       = module.krantz_cloud.group
  description = "The name of the IAM group for krantz.cloud"
}

output "krantz_dev" {
  value       = module.krantz_dev.group
  description = "The name of the IAM group for krantz.dev"
}

output "krantz_social" {
  value       = module.krantz_social.group
  description = "The name of the IAM group for krantz.social"
}
