module "s3_bucket" {
  source = "./modules/s3-bucket"

  name_suffix = var.bucket_name_suffix
}
