terraform {
  backend "s3" {
    bucket         = "learn-terraform-state-000000000"
    key            = "301-remote-state.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "learn-terraform-state-lock"
  }
}
