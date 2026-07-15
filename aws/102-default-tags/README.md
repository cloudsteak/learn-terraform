# AWS Provider Default Tags

A minimal Terraform configuration for AWS that applies tags to every supported resource through the provider's `default_tags` block.

## Purpose

This example builds on [101-basic](../101-basic/) and shows:

- How to configure `default_tags` in the AWS provider
- How provider-level tags are merged onto resources automatically
- How to verify applied tags via outputs

No modules or remote state are included.

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
aws/102-default-tags/
├── providers.tf   # Terraform version, provider requirements, default_tags
├── variables.tf   # Input variables (including tag values)
├── main.tf        # Resource definitions
├── outputs.tf     # Output values (including applied tags)
└── README.md      # This file
```

| File | Responsibility |
|------|----------------|
| `providers.tf` | Pins Terraform and the `aws` provider, sets region, and defines `default_tags` |
| `variables.tf` | Defines configurable inputs with defaults |
| `main.tf` | Declares the infrastructure to create |
| `outputs.tf` | Exposes useful values after apply |

## What gets created

One S3 bucket with provider default tags applied:

| Resource | Name (default) | Region (default) |
|----------|----------------|------------------|
| S3 bucket | `{account-id}-learn-terraform-default-tags` | `eu-north-1` |

Default tags applied to every supported resource:

| Tag | Default value |
|-----|---------------|
| `Environment` | `dev` |
| `Project` | `learn-terraform` |
| `ManagedBy` | `terraform` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | `eu-north-1` | AWS region for the S3 bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-default-tags` | Suffix appended to the account ID for the bucket name |
| `environment` | `string` | `dev` | Value for the `Environment` default tag |
| `project` | `string` | `learn-terraform` | Value for the `Project` default tag |

Override defaults with a `.tfvars` file or command-line flags:

```bash
terraform apply -var="environment=staging" -var="project=my-app"
```

Or create `terraform.tfvars` locally (this file is gitignored by default):

```hcl
environment = "staging"
project     = "my-app"
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created S3 bucket |
| `bucket_arn` | ARN of the created S3 bucket |
| `bucket_tags` | Tags on the bucket, including provider `default_tags` |

After apply, inspect the tags:

```bash
terraform output bucket_tags
```

## Usage

From this directory:

```bash
cd aws/102-default-tags

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

## How default_tags works

The `default_tags` block in `providers.tf` sets tags at the provider level. Terraform merges them onto every resource that supports tagging, so you do not repeat the same tags on each resource block.

Resource-level `tags` are merged with provider defaults. If a resource sets a tag key that also exists in `default_tags`, the resource-level value wins.

Not every AWS resource supports tags. Check the [AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) for tag support on specific resources.

## Authentication

The AWS provider uses credentials from the AWS CLI or environment variables by default. After `aws configure`, Terraform uses your active profile.

For CI/CD, use IAM roles, OIDC, or access keys via environment variables. See [AWS provider authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

## Next steps

Once you understand provider default tags, you can extend this by:

- Adding resource-specific tags alongside provider defaults
- Using `ignore_tags` in the provider to skip certain tag keys
- Splitting logic into modules (see [201-modules](../201-modules/))
- Storing state remotely (see [301-remote-state](../301-remote-state/))
