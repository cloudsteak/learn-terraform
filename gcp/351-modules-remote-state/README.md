# GCP Modules with Remote State

A minimal **Terraform** configuration that creates a Cloud Storage bucket through a local module and stores state in a Cloud Storage bucket.

This example combines [201-modules](../201-modules/) and [301-remote-state](../301-remote-state/). It uses Terraform's native remote state backend — not Terragrunt.

## Purpose

This example shows:

- How to call a reusable local module from a root configuration
- How module inputs and outputs connect to the root module
- How to store Terraform state remotely in Cloud Storage via `backend.tf`
- How bootstrap scripts prepare the backend before `terraform init`

The state backend is created outside Terraform by the bootstrap scripts. Terraform manages the workload bucket through a module.

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

Authenticate before running the bootstrap scripts or Terraform:

```bash
gcloud auth login
gcloud auth application-default login
```

## Project structure

```
gcp/351-modules-remote-state/
├── backend.tf              # Remote state backend configuration
├── bootstrap-backend.sh    # Create backend storage (Bash)
├── bootstrap-backend.ps1   # Create backend storage (PowerShell)
├── providers.tf            # Terraform version, provider requirements, and Google provider
├── variables.tf            # Root module input variables
├── main.tf                 # Module call
├── outputs.tf              # Root module outputs
├── modules/
│   └── gcs-bucket/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md
```

| File | Responsibility |
|------|----------------|
| `backend.tf` | Native Terraform `gcs` backend settings |
| `bootstrap-backend.sh` | Prompts for project, generates bucket name, updates `backend.tf` (Bash) |
| `bootstrap-backend.ps1` | Prompts for project, generates bucket name, updates `backend.tf` (PowerShell) |
| `main.tf` | Calls the local `gcs-bucket` module |
| `modules/gcs-bucket/` | Reusable module that creates one Cloud Storage bucket |

## What gets created

### By bootstrap scripts (remote state backend)

| Resource | Name (default) | Purpose |
|----------|----------------|---------|
| Cloud Storage bucket | `learn-terraform-state-{project-id}-` + 9 random digits | Stores Terraform state objects |

State for this project is stored under the prefix `351-modules-remote-state`.

### By Terraform (workload)

| Resource | Name (default) | Location (default) |
|----------|----------------|--------------------|
| Cloud Storage bucket | `{project-id}-learn-terraform-modules-remote-state` | `europe-north1` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `europe-north1` | GCP location for the bucket |
| `bucket_name_suffix` | `string` | `learn-terraform-modules-remote-state` | Suffix appended to the project ID for the bucket name |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created Cloud Storage bucket |
| `bucket_url` | URL of the created Cloud Storage bucket |

## Usage

### Step 1 — Bootstrap the Cloud Storage backend

Run one of the bootstrap scripts before `terraform init`:

**Bash:**

```bash
cd gcp/351-modules-remote-state
./bootstrap-backend.sh
```

**PowerShell:**

```powershell
cd gcp/351-modules-remote-state
./bootstrap-backend.ps1
```

The script lists your GCP projects, asks which one to use, generates a unique state bucket name, updates `backend.tf`, and creates the backend bucket.

If you already bootstrapped [301-remote-state](../301-remote-state/) with the same `backend.tf` values, you can reuse that state bucket. This example uses a separate state prefix so both projects can share the same bucket.

### Step 2 — Run Terraform

```bash
terraform init
terraform plan
terraform apply
```

Use the `terraform` CLI directly — not `terragrunt`. State is stored remotely in Cloud Storage.

### Cleanup

Remove workload resources first:

```bash
terraform destroy
```

Then delete the backend bucket if you no longer need it:

```bash
gcloud storage rm --recursive gs://YOUR-STATE-BUCKET-NAME
```

## How the module is used

The root module passes variables into the local module:

```hcl
module "gcs_bucket" {
  source = "./modules/gcs-bucket"

  location    = var.location
  name_suffix = var.bucket_name_suffix
}
```

Module outputs are exposed at the root level:

```hcl
output "bucket_name" {
  value = module.gcs_bucket.name
}
```

## Authentication

The bootstrap scripts and Terraform use Application Default Credentials by default.

## Next steps

- Compare with [201-modules](../201-modules/) to see the same module pattern with local state
- Use separate `prefix` values in `backend.tf` for other projects sharing the same state bucket
- Publish the module to a registry or Git repository
