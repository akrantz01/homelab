output "role_arn" {
  value       = module.project.role_arn
  description = "The ARN of the role the tailfed repository assumes"
}
