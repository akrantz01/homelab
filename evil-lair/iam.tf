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
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
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
