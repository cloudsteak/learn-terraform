terraform {
  backend "gcs" {
    bucket = "learn-terraform-state-000000000"
    prefix = "351-modules-remote-state"
  }
}
