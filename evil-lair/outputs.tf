output "github_webhook_secret" {
  description = "The secret used to sign the GitHub webhook payload"
  value       = random_password.github_secret.result
  sensitive   = true
}
