# Azure Modules with Remote State

A minimal **Terraform** configuration that creates a resource group through a local module and stores state in an Azure Storage account.

This example combines [301-modules](../301-modules/) and [201-remote-state](../201-remote-state/). It uses Terraform's native remote state backend — not Terragrunt.

## Purpose

This example shows:

- How to call a reusable local module from a root configuration
- How module inputs and outputs connect to the root module
- How to store Terraform state remotely in Azure Storage via `backend.tf`
- How bootstrap scripts prepare the backend before `terraform init`

The state backend is created outside Terraform by the bootstrap scripts. Terraform manages the workload resource group through a module.

## Prerequisites

- [tenv](https://tofuutils.github.io/tenv/) for Terraform version management — see [tenv.md](../../tenv.md)
- Terraform `>= 1.15.0` (pinned to **1.15.7** via `.terraform-version`)
- [azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) `~> 4.80`
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in

Install and select the pinned Terraform version:

```bash
tenv tf install    # reads .terraform-version
terraform version  # should report 1.15.7
```

Authenticate with Azure before running the bootstrap scripts or Terraform:

```bash
az login
```

## Project structure

```
azure/302-modules-remote-state/
├── backend.tf              # Remote state backend configuration
├── bootstrap-backend.sh    # Create backend storage (Bash)
├── bootstrap-backend.ps1   # Create backend storage (PowerShell)
├── providers.tf            # Terraform version, provider requirements, and Azure provider
├── variables.tf            # Root module input variables
├── main.tf                 # Module call
├── outputs.tf              # Root module outputs
├── modules/
│   └── resource-group/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md
```

| File | Responsibility |
|------|----------------|
| `backend.tf` | Native Terraform `azurerm` backend settings |
| `bootstrap-backend.sh` | Prompts for subscription, generates storage account name, updates `backend.tf` (Bash) |
| `bootstrap-backend.ps1` | Prompts for subscription, generates storage account name, updates `backend.tf` (PowerShell) |
| `main.tf` | Calls the local `resource-group` module |
| `modules/resource-group/` | Reusable module that creates one resource group |

## What gets created

### By bootstrap scripts (remote state backend)

| Resource | Name (default) | Purpose |
|----------|----------------|---------|
| Resource group | `rg-learn-terraform-state` | Holds the remote state storage account |
| Storage account | `terraform` + 9 random digits (for example `terraform342254543`) | Stores Terraform state blobs |
| Blob container | `tfstate` | Container for the state file |

State for this project is stored under the key `302-modules-remote-state.tfstate`.

### By Terraform (workload)

| Resource | Name (default) | Location (default) |
|----------|----------------|--------------------|
| Resource group | `rg-learn-terraform-modules-remote-state` | `Sweden Central` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `Sweden Central` | Azure region for the resource group |
| `resource_group_name` | `string` | `rg-learn-terraform-modules-remote-state` | Name of the resource group |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Name of the created resource group |
| `resource_group_id` | Azure resource ID of the resource group |

## Usage

### Step 1 — Bootstrap the Azure storage backend

Run one of the bootstrap scripts before `terraform init`:

**Bash:**

```bash
cd azure/302-modules-remote-state
./bootstrap-backend.sh
```

**PowerShell:**

```powershell
cd azure/302-modules-remote-state
./bootstrap-backend.ps1
```

The script lists your Azure subscriptions, asks which one to use, generates a random storage account name like `terraform342254543`, updates `backend.tf`, and creates the backend resources.

If you already bootstrapped [201-remote-state](../201-remote-state/) with the same `backend.tf` values, you can reuse that storage account. This example uses a separate state key so both projects can share the same container.

### Step 2 — Run Terraform

```bash
terraform init
terraform plan
terraform apply
```

Use the `terraform` CLI directly — not `terragrunt`. State is stored remotely in Azure Storage.

### Cleanup

Remove workload resources first:

```bash
terraform destroy
```

Then delete the backend storage if you no longer need it:

```bash
az group delete --name rg-learn-terraform-state --yes --no-wait
```

## How the module is used

The root module passes variables into the local module:

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
}
```

Module outputs are exposed at the root level:

```hcl
output "resource_group_name" {
  value = module.resource_group.name
}
```

## Authentication

The bootstrap scripts and Terraform use credentials from the Azure CLI by default. After `az login`, both the `azurerm` provider and backend use your active account.

## Next steps

- Compare with [301-modules](../301-modules/) to see the same module pattern with local state
- Use separate `key` values in `backend.tf` for other projects sharing the same storage container
- Publish the module to a registry or Git repository
