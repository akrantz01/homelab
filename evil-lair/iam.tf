data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "evil_lair" {
  statement {
    sid = "SSMParameterStoreSDBAccess"

    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:AddTagsToResource",
      "ssm:RemoveTagsFromResource",
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/salt/*",
    ]
  }
}

resource "aws_iam_role" "evil_lair" {
  name               = "ShipInstanceRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "evil_lair" {
  name   = "ShipInstanceRolePolicy"
  role   = aws_iam_role.evil_lair.id
  policy = data.aws_iam_policy_document.evil_lair.json
}

resource "aws_iam_instance_profile" "evil_lair" {
  name = "ShipInstanceProfile"
  role = aws_iam_role.evil_lair.name
}
