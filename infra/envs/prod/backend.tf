terraform {
  backend "s3" {
    key          = "libris/prod/statefile.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Activates S3 native state locking
  }
}