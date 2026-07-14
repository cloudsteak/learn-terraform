module "gcs_bucket" {
  source = "./modules/gcs-bucket"

  location    = var.location
  name_suffix = var.bucket_name_suffix
}
