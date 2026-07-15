variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "bucket_name_suffix" {
  type    = string
  default = "learn-terraform-default-tags"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "learn-terraform"
}
