locals {
  domain = "${var.subdomain}.${var.domain}"

  letsencrypt_subdomain = var.letsencrypt_staging ? "acme-staging-v02" : "acme-v02"
  letsencrypt_server    = "https://${local.letsencrypt_subdomain}.api.letsencrypt.org/directory"
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["debian-11-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "ssh" {
  key_name   = "ShipSSHKey"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_instance" "evil_lair" {
  ami           = data.aws_ami.debian.id
  instance_type = "t3a.small"

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.evil_lair.id]

  key_name             = aws_key_pair.ssh.key_name
  iam_instance_profile = aws_iam_instance_profile.evil_lair.name

  credit_specification {
    cpu_credits = "unlimited"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8

    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    saltstack_version = "onedir"

    fileserver_conf = file("${path.module}/configs/fileserver.conf")
    sdb_conf        = file("${path.module}/configs/sdb.conf")

    nginx_default_conf = file("${path.module}/configs/nginx.default.conf")
    nginx_webhook_conf = templatefile("${path.module}/templates/nginx.webhook.conf.tpl", {
      domain = local.domain
    })

    domain             = local.domain
    letsencrypt_email  = var.letsencrypt_email
    letsencrypt_server = local.letsencrypt_server
  })
  user_data_replace_on_change = true

  tags = {
    Name = "EvilLair"
  }
}

resource "local_sensitive_file" "ssh" {
  count = var.enable_ssh ? 1 : 0

  filename = "${path.module}/evil_lair.pem"
  content  = tls_private_key.ssh.private_key_openssh

  file_permission = "0600"
}
