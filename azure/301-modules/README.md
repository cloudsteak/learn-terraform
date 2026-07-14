# Azure Modules Terraform

A minimal **Terraform** configuration that creates a resource group through a local module. State is stored locally on your machine.

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
- [azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) `~> 4.80`
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in

Install and select the pinned Terraform version:

```bash
tenv tf install    # reads .terraform-version
terraform version  # should report 1.15.7
```

Authenticate with Azure before running Terraform:

```bash
az login
```

## Project structure

```
azure/301-modules/
├── providers.tf                 # Terraform version, provider requirements, and Azure provider
├── variables.tf                 # Root module input variables
├── main.tf                      # Module call
├── outputs.tf                   # Root module outputs
├── modules/
│   └── resource-group/
│       ├── main.tf              # Resource group definition
│       ├── variables.tf         # Module input variables
│       └── outputs.tf           # Module outputs
└── README.md                    # This file
```

| File | Responsibility |
|------|----------------|
| `main.tf` | Calls the local `resource-group` module |
| `variables.tf` | Defines inputs passed into the module |
| `outputs.tf` | Exposes values returned from the module |
| `modules/resource-group/` | Reusable module that creates one resource group |

## What gets created

One Azure resource group, created by the local module:

| Resource | Name (default) | Location (default) |
|----------|----------------|--------------------|
| Resource group | `rg-learn-terraform-modules` | `Sweden Central` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `Sweden Central` | Azure region for the resource group |
| `resource_group_name` | `string` | `rg-learn-terraform-modules` | Name of the resource group |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Name of the created resource group |
| `resource_group_id` | Azure resource ID of the resource group |

## Usage

From this directory:

```bash
cd azure/301-modules

terraform init
terraform plan
terraform apply
```

Terraform stores state locally in `terraform.tfstate` in this directory.

Confirm with `yes` when prompted, or use `-auto-approve` for non-interactive runs.

## How the module is used

The root module passes variables into the local module:

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
}
```

The root module reads results through module outputs:

```hcl
output "resource_group_name" {
  value = module.resource_group.name
}
```

## Authentication

The Azure provider uses credentials from the Azure CLI by default. After `az login`, Terraform uses your active account.

## Next steps

Once you understand local modules, you can:

- Add more resources to the module
- Call the same module multiple times with different inputs
- Publish the module to a registry or Git repository
- Combine modules with remote state from [201-remote-state](../201-remote-state/)
