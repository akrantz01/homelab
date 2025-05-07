data "aws_ami" "nixos" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/24.11*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

data "http" "ssh_keys" {
  method = "GET"
  url    = "https://github.com/akrantz01.keys"

  request_headers = {
    Accept = "text/plain"
  }
}

locals {
  key = coalesce(split("\n", data.http.ssh_keys.response_body)...)
}

resource "aws_key_pair" "github" {
  key_name   = "github"
  public_key = local.key
}

resource "aws_instance" "idp" {
  tags = {
    Name = "idp"
  }

  ami           = data.aws_ami.nixos.id
  instance_type = "t4g.small"

  subnet_id              = local.subnet_id
  key_name               = aws_key_pair.github.key_name
  vpc_security_group_ids = [aws_security_group.idp.id]

  associate_public_ip_address = true

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/user-data.sh.tfpl", {
    flake    = var.flake
    host_key = var.host_key
  })

  ebs_optimized = true
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 50
    volume_type           = "gp3"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  metadata_options {
    http_endpoint      = "enabled"
    http_protocol_ipv6 = "enabled"
    http_tokens        = "required"
  }
}
