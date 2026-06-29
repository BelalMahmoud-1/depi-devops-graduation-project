terraform {
  backend "s3" {
    bucket = "amazona-terraform-state-608645726975"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
