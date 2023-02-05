resource "aws_vpc" "main" {
  cidr_block = "172.24.0.0/20"

  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "ShipVPC"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ShipIGW"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  cidr_block      = cidrsubnet(aws_vpc.main.cidr_block, 4, 0)
  ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)

  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true

  private_dns_hostname_type_on_launch         = "ip-name"
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "ShipPublicSubnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.public.id
  }

  tags = {
    Name = "ShipPublicRTB"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "evil_lair" {
  name        = "ShipSecurityGroup"
  description = "Allow traffic from the internet to the SaltStack master"
  vpc_id      = aws_vpc.main.id

  # Allow SaltStack minions
  dynamic "ingress" {
    for_each = [4505, 4506]

    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"

      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Allow HTTP/S
  dynamic "ingress" {
    for_each = [80, 443]

    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"

      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Optionally enable SSH
  dynamic "ingress" {
    for_each = var.enable_ssh ? [22] : []

    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"

      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
