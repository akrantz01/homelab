module "media" {
  source = "../../modules/bucket"

  name = "login-krantz-dev-media"

  cors = [
    {
      allowed_origins = [local.domain]
      allowed_methods = ["GET"]
      allowed_headers = ["Authorization"]
      max_age_seconds = 3000
    }
  ]
}
