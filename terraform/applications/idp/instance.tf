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

resource "aws_instance" "idp" {
  tags = {
    Name = "idp"
  }

  ami           = data.aws_ami.nixos.id
  instance_type = "t4g.medium"

  monitoring = true

  subnet_id              = local.subnet_id
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
