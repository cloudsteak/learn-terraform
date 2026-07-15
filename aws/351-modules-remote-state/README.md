# AWS Modules with Remote State

A minimal **Terraform** configuration that creates an S3 bucket through a local module and stores state in an S3 bucket with S3-native lockfile locking.

This example combines [201-modules](../201-modules/) and [301-remote-state](../301-remote-state/). It uses Terraform's native remote state backend — not Terragrunt.

## Purpose

This example shows:

- How to call a reusable local module from a root configuration
- How module inputs and outputs connect to the root module
- How to store Terraform state remotely in S3 via `backend.tf`
- How bootstrap scripts prepare the backend before `terraform init`

The state backend is created outside Terraform by the bootstrap scripts. Terraform manages the workload S3 bucket through a module.

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

Configure AWS credentials before running the bootstrap scripts or Terraform:

```bash
aws configure
```

## Project structure

```
aws/351-modules-remote-state/
├── backend.tf              # Remote state backend configuration
├── bootstrap-backend.sh    # Create backend storage (Bash)
├── bootstrap-backend.ps1   # Create backend storage (PowerShell)
├── providers.tf            # Terraform version, provider requirements, and AWS provider
├── variables.tf            # Root module input variables
├── main.tf                 # Module call
├── outputs.tf              # Root module outputs
├── modules/
│   └── s3-bucket/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md
```

| File | Responsibility |
|------|----------------|
| `backend.tf` | Native Terraform `s3` backend settings |
| `bootstrap-backend.sh` | Prompts for profile, generates bucket name, updates `backend.tf` (Bash) |
| `bootstrap-backend.ps1` | Prompts for profile, generates bucket name, updates `backend.tf` (PowerShell) |
| `main.tf` | Calls the local `s3-bucket` module |
| `modules/s3-bucket/` | Reusable module that creates one S3 bucket |

## What gets created

### By bootstrap scripts (remote state backend)

| Resource | Name (default) | Purpose |
|----------|----------------|---------|
| S3 bucket | `learn-terraform-state-{account-id}-` + 9 random digits | Stores Terraform state objects and lock files |

State for this project is stored under the key `351-modules-remote-state.tfstate`.

### By Terraform (workload)

| Resource | Name (default) | Region (default) |
|----------|----------------|------------------|
| S3 bucket | `{account-id}-learn-terraform-modules-remote-state` | `eu-north-1` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | `eu-north-1` | AWS region for the S3 bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-modules-remote-state` | Suffix appended to the account ID for the bucket name |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created S3 bucket |
| `bucket_arn` | ARN of the created S3 bucket |

## Usage

### Step 1 — Bootstrap the AWS storage backend

Run one of the bootstrap scripts before `terraform init`:

**Bash:**

```bash
cd aws/351-modules-remote-state
./bootstrap-backend.sh
```

**PowerShell:**

```powershell
cd aws/351-modules-remote-state
./bootstrap-backend.ps1
```

The script lists your AWS profiles, asks which one to use (if multiple exist), generates a unique state bucket name, updates `backend.tf`, and creates the backend resources.

If you already bootstrapped [301-remote-state](../301-remote-state/) with the same `backend.tf` values, you can reuse that state bucket. This example uses a separate state key so both projects can share the same bucket.

### Step 2 — Run Terraform

```bash
terraform init
terraform plan
terraform apply
```

Use the `terraform` CLI directly — not `terragrunt`. State is stored remotely in S3.

### Cleanup

Remove workload resources first:

```bash
terraform destroy
```

Then delete the backend storage if you no longer need it:

```bash
./cleanup-backend.sh
```

Or delete the bucket directly:

```bash
aws s3 rb s3://YOUR-STATE-BUCKET-NAME --force
```

## How the module is used

The root module passes variables into the local module:

```hcl
module "s3_bucket" {
  source = "./modules/s3-bucket"

  name_suffix = var.bucket_name_suffix
}
```

Module outputs are exposed at the root level:

```hcl
output "bucket_name" {
  value = module.s3_bucket.name
}
```

## Authentication

The bootstrap scripts and Terraform use credentials from the AWS CLI or environment variables by default.

## Next steps

- Compare with [201-modules](../201-modules/) to see the same module pattern with local state
- Use separate `key` values in `backend.tf` for other projects sharing the same state bucket
- Publish the module to a registry or Git repository
