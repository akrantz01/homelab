terraform {
  required_version = "~> 1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
  }
}

resource "aws_iam_user" "user" {
  name = var.name
  path = var.path
}

resource "aws_iam_user_group_membership" "membership" {
  user   = aws_iam_user.user.name
  groups = var.groups
}

resource "aws_iam_user_policy_attachment" "attachment" {
  for_each = toset(var.policies)

  user       = aws_iam_user.user.name
  policy_arn = each.value
}

resource "aws_iam_access_key" "user" {
  user = aws_iam_user.user.name
}