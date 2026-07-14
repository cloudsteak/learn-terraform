# AWS Basic Terraform

A minimal Terraform configuration for AWS. It creates a single S3 bucket and demonstrates the smallest useful project layout.

## Purpose

This example is meant for learning. It shows:

- How to declare Terraform and provider requirements
- How to configure the AWS provider
- How to define variables, a resource, and outputs
- The standard file split used in real Terraform projects

Nothing else is included: no modules, remote state backend, or additional AWS resources.

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
# or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
```

## Project structure

```
aws/101-basic/
├── providers.tf   # Terraform version, provider requirements, and AWS provider
├── variables.tf   # Input variables
├── main.tf        # Resource definitions
├── outputs.tf     # Output values
└── README.md      # This file
```

| File | Responsibility |
|------|----------------|
| `providers.tf` | Pins Terraform and the `aws` provider, and configures the AWS region |
| `variables.tf` | Defines configurable inputs with defaults |
| `main.tf` | Declares the infrastructure to create |
| `outputs.tf` | Exposes useful values after apply |

## What gets created

One S3 bucket. The bucket name is prefixed with your AWS account ID so it stays globally unique:

| Resource | Name (default) | Region (default) |
|----------|----------------|------------------|
| S3 bucket | `{account-id}-learn-terraform-basic` | `eu-north-1` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | `eu-north-1` | AWS region for the S3 bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-basic` | Suffix appended to the account ID for the bucket name |

Override defaults with a `.tfvars` file or command-line flags:

```bash
terraform apply -var="region=eu-west-1" -var="bucket_name_suffix=my-example"
```

Or create `terraform.tfvars` locally (this file is gitignored by default):

```hcl
region             = "eu-west-1"
bucket_name_suffix = "my-example"
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created S3 bucket |
| `bucket_arn` | ARN of the created S3 bucket |

## Usage

From this directory:

```bash
cd aws/101-basic

# Download the AWS provider
terraform init

# Preview changes
terraform plan

# Create the S3 bucket
terraform apply

# Remove the bucket when finished
terraform destroy
```

Confirm with `yes` when prompted, or use `-auto-approve` for non-interactive runs.

## Authentication

The AWS provider uses credentials from the AWS CLI or environment variables by default. After `aws configure`, Terraform uses your active profile.

For CI/CD, use IAM roles, OIDC, or access keys via environment variables. See [AWS provider authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

## Next steps

Once you understand this layout, you can extend it by:

- Adding more resources (for example bucket versioning or encryption)
- Introducing a remote backend (for example S3 with DynamoDB locking)
- Splitting logic into modules
- Using separate `.tfvars` files per environment
