terraform {
  backend "s3" {
    bucket         = "terraform-state-020245980377"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
