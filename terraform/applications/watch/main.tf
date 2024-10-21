terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "0.9.0"
    }
  }
}

resource "b2_bucket" "storage" {
  bucket_type = "allPrivate"
  bucket_name = "watch-krantz-dev"

  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
}
