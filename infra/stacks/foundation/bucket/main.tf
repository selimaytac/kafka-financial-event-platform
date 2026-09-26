# SeaweedFS speaks the S3 API; the AWS provider manages the bucket declaratively,
# so drift (e.g. versioning switched off) shows up in `tofu plan`.
provider "aws" {
  region     = "us-east-1"
  access_key = var.s3_access_key
  secret_key = var.s3_secret_key

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = var.s3_endpoint
  }
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket

  # Holds the state of every other stack; removing it is a deliberate runbook step.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}
