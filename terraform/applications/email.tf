resource "aws_sesv2_configuration_set" "default" {
  configuration_set_name = "default"

  delivery_options {
    tls_policy = "OPTIONAL"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }
}

module "krantz_cloud_email" {
  source = "../modules/ses-identity"

  domain = "krantz.cloud"

  configuration_set = aws_sesv2_configuration_set.default.id
}

module "krantz_dev_email" {
  source = "../modules/ses-identity"

  domain = "krantz.dev"

  configuration_set = aws_sesv2_configuration_set.default.id
}

module "krantz_social_email" {
  source = "../modules/ses-identity"

  domain = "krantz.social"

  configuration_set = aws_sesv2_configuration_set.default.id
}
