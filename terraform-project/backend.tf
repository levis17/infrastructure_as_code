terraform {
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
