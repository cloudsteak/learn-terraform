# AWS Terraform Examples

## [101-basic](./101-basic/)

Minimal Terraform setup for AWS: one S3 bucket and a standard project file layout.

→ [README](./101-basic/README.md)

## [102-default-tags](./102-default-tags/)

Provider-level `default_tags` applied automatically to every supported AWS resource.

→ [README](./102-default-tags/README.md)

## [201-modules](./201-modules/)

Simple local module usage with local state. A root module calls a reusable `s3-bucket` module.

→ [README](./201-modules/README.md)

## [301-remote-state](./301-remote-state/)

Simple remote state with Terraform's native `s3` backend in `backend.tf`. Bootstrap scripts create the S3 state bucket; use `terraform init`, not Terragrunt.

→ [README](./301-remote-state/README.md)

## [351-modules-remote-state](./351-modules-remote-state/)

Simple local module usage with remote state in S3. Combines the module pattern from 201 with the backend setup from 301.

→ [README](./351-modules-remote-state/README.md)
