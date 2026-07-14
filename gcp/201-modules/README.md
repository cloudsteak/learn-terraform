# GCP Modules Terraform

A minimal **Terraform** configuration that creates a Cloud Storage bucket through a local module. State is stored locally on your machine.

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
- [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest) `~> 5.0`
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated

Install and select the pinned Terraform version:

```bash
tenv tf install    # reads .terraform-version
terraform version  # should report 1.15.7
```

Authenticate and set a default project:

```bash
gcloud auth application-default login
gcloud config set project YOUR-PROJECT-ID
```

## Project structure

```
gcp/201-modules/
├── providers.tf                 # Terraform version, provider requirements, and Google provider
├── variables.tf                 # Root module input variables
├── main.tf                      # Module call
├── outputs.tf                   # Root module outputs
├── modules/
│   └── gcs-bucket/
│       ├── main.tf              # Cloud Storage bucket definition
│       ├── variables.tf         # Module input variables
│       └── outputs.tf           # Module outputs
└── README.md                    # This file
```

| File | Responsibility |
|------|----------------|
| `main.tf` | Calls the local `gcs-bucket` module |
| `variables.tf` | Defines inputs passed into the module |
| `outputs.tf` | Exposes values returned from the module |
| `modules/gcs-bucket/` | Reusable module that creates one Cloud Storage bucket |

## What gets created

One Cloud Storage bucket, created by the local module:

| Resource | Name (default) | Location (default) |
|----------|----------------|--------------------|
| Cloud Storage bucket | `{project-id}-learn-terraform-modules` | `europe-north1` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `europe-north1` | GCP location for the bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-modules` | Suffix appended to the project ID for the bucket name |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created Cloud Storage bucket |
| `bucket_url` | URL of the created Cloud Storage bucket |

## Usage

From this directory:

```bash
cd gcp/201-modules

terraform init
terraform plan
terraform apply
```

Terraform stores state locally in `terraform.tfstate` in this directory.

Confirm with `yes` when prompted, or use `-auto-approve` for non-interactive runs.

## How the module is used

The root module passes variables into the local module:

```hcl
module "gcs_bucket" {
  source = "./modules/gcs-bucket"

  location    = var.location
  name_suffix = var.bucket_name_suffix
}
```

The root module reads results through module outputs:

```hcl
output "bucket_name" {
  value = module.gcs_bucket.name
}
```

## Authentication

The Google provider uses Application Default Credentials by default.

## Next steps

Once you understand local modules, you can:

- Add more resources to the module
- Call the same module multiple times with different inputs
- Publish the module to a registry or Git repository
- Combine modules with remote state from [301-remote-state](../301-remote-state/)
