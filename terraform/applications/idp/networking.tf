data "aws_vpc" "default" {
  default = true
  state   = "available"
}

data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
  id     = var.subnet_id
  state  = "available"
}

resource "aws_security_group" "idp" {
  name   = "idp"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.idp.id
  type              = "ingress"

  protocol  = "tcp"
  from_port = 22
  to_port   = 22

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
