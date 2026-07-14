# AWS Modules Terraform

A minimal **Terraform** configuration that creates an S3 bucket through a local module. State is stored locally on your machine.

## Purpose

This example builds on [101-basic](../101-basic/). It shows:

- How to define a reusable local module
- How to call a module from a root configuration
- How module inputs and outputs connect to the root module
- How Terraform works with local state (no remote backend)

Nothing else is included: no remote state backend, no nested module chains, or registry modules.

## Prerequisites

- [tenv](https://tofuutils.github.io/tenv/) for Terraform version management — see [tenv.md](../../tenv.md)
- Terraform `>= 1.15.0` (pinned to **1.15.7** via `.terraform-version`)
- [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest) `~> 5.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured

Install and select the pinned Terraform version:

```bash
tenv tf install    # reads .terraform-version
terraform version  # should report 1.15.7
```

Configure AWS credentials before running Terraform:

```bash
aws configure
```

## Project structure

```
aws/201-modules/
├── providers.tf                 # Terraform version, provider requirements, and AWS provider
├── variables.tf                 # Root module input variables
├── main.tf                      # Module call
├── outputs.tf                   # Root module outputs
├── modules/
│   └── s3-bucket/
│       ├── main.tf              # S3 bucket definition
│       ├── variables.tf         # Module input variables
│       └── outputs.tf           # Module outputs
└── README.md                    # This file
```

| File | Responsibility |
|------|----------------|
| `main.tf` | Calls the local `s3-bucket` module |
| `variables.tf` | Defines inputs passed into the module |
| `outputs.tf` | Exposes values returned from the module |
| `modules/s3-bucket/` | Reusable module that creates one S3 bucket |

## What gets created

One S3 bucket, created by the local module:

| Resource | Name (default) | Region (default) |
|----------|----------------|------------------|
| S3 bucket | `{account-id}-learn-terraform-modules` | `eu-north-1` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | `eu-north-1` | AWS region for the S3 bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-modules` | Suffix appended to the account ID for the bucket name |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created S3 bucket |
| `bucket_arn` | ARN of the created S3 bucket |

## Usage

From this directory:

```bash
cd aws/201-modules

terraform init
terraform plan
terraform apply
```

Terraform stores state locally in `terraform.tfstate` in this directory.

Confirm with `yes` when prompted, or use `-auto-approve` for non-interactive runs.

## How the module is used

The root module passes variables into the local module:

```hcl
module "s3_bucket" {
  source = "./modules/s3-bucket"

  name_suffix = var.bucket_name_suffix
}
```

The root module reads results through module outputs:

```hcl
output "bucket_name" {
  value = module.s3_bucket.name
}
```

## Authentication

The AWS provider uses credentials from the AWS CLI or environment variables by default.

## Next steps

Once you understand local modules, you can:

- Add more resources to the module
- Call the same module multiple times with different inputs
- Publish the module to a registry or Git repository
- Combine modules with remote state from [301-remote-state](../301-remote-state/)
