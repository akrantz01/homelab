# Now managed by bootstrap/sops.tf
removed {
  from = aws_kms_key.sops

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_kms_alias.sops

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_kms_key_policy.sops

  lifecycle {
    destroy = false
  }
}
