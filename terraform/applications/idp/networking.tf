resource "random_integer" "subnet_index" {
  min = 0
  max = length(var.public_subnets) - 1
}

locals {
  subnet_id = var.public_subnets[random_integer.subnet_index.result]
}

resource "aws_security_group" "idp" {
  name   = "idp"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.idp.id
  type              = "ingress"

  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.idp.id
  type              = "ingress"

  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.idp.id
  type              = "egress"

  protocol  = "-1"
  from_port = 0
  to_port   = 0

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
