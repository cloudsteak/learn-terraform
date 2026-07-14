# GCP Basic Terraform

A minimal Terraform configuration for Google Cloud. It creates a single Cloud Storage bucket and demonstrates the smallest useful project layout.

## Purpose

This example is meant for learning. It shows:

- How to declare Terraform and provider requirements
- How to configure the Google provider
- How to define variables, a resource, and outputs
- The standard file split used in real Terraform projects

Nothing else is included: no modules, remote state backend, or additional GCP resources.

## Prerequisites

- [tenv](https://tofuutils.github.io/tenv/) for Terraform version management — see [tenv.md](../../tenv.md)
- Terraform `>= 1.15.0` (pinned to **1.15.7** via `.terraform-version`)
- [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest) `~> 5.0`
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated

Install and select the pinned Terraform version:

```bash
tenv tf install    # reads .terraform-version
terraform version  # should report 1.15.7
```

Authenticate and set a default project before running Terraform:

```bash
gcloud auth application-default login
gcloud config set project YOUR-PROJECT-ID
```

## Project structure

```
gcp/101-basic/
├── providers.tf   # Terraform version, provider requirements, and Google provider
├── variables.tf   # Input variables
├── main.tf        # Resource definitions
├── outputs.tf     # Output values
└── README.md      # This file
```

| File | Responsibility |
|------|----------------|
| `providers.tf` | Pins Terraform and the `google` provider, and configures the region |
| `variables.tf` | Defines configurable inputs with defaults |
| `main.tf` | Declares the infrastructure to create |
| `outputs.tf` | Exposes useful values after apply |

## What gets created

One Cloud Storage bucket. The bucket name is prefixed with your GCP project ID so it stays globally unique:

| Resource | Name (default) | Location (default) |
|----------|----------------|--------------------|
| Cloud Storage bucket | `{project-id}-learn-terraform-basic` | `europe-north1` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `europe-north1` | GCP location for the bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-basic` | Suffix appended to the project ID for the bucket name |

Override defaults with a `.tfvars` file or command-line flags:

```bash
terraform apply -var="location=europe-west1" -var="bucket_name_suffix=my-example"
```

Or create `terraform.tfvars` locally (this file is gitignored by default):

```hcl
location           = "europe-west1"
bucket_name_suffix = "my-example"
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created Cloud Storage bucket |
| `bucket_url` | URL of the created Cloud Storage bucket |

## Usage

From this directory:

```bash
cd gcp/101-basic

# Download the Google provider
terraform init

# Preview changes
terraform plan

# Create the bucket
terraform apply

# Remove the bucket when finished
terraform destroy
```

Confirm with `yes` when prompted, or use `-auto-approve` for non-interactive runs.

## Authentication

The Google provider uses [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials) by default. After `gcloud auth application-default login`, Terraform uses those credentials.

For CI/CD, use a service account key or Workload Identity Federation. See [Google provider authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

## Next steps

Once you understand this layout, you can extend it by:

- Adding more resources (for example bucket versioning or lifecycle rules)
- Introducing a remote backend (for example Cloud Storage)
- Splitting logic into modules
- Using separate `.tfvars` files per environment
