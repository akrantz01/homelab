output "identity_provider" {
  description = "The OpenID Connect provider for Tailscale"
  value       = aws_iam_openid_connect_provider.tailfed.arn
  depends_on  = [aws_iam_openid_connect_provider.tailfed]
}
