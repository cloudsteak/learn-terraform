data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "main" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.bucket_name_suffix}"
}
