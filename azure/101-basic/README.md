# Azure Basic Terraform

A minimal Terraform configuration for Azure. It creates a single resource group and demonstrates the smallest useful project layout.

## Purpose

This example is meant for learning. It shows:

- How to declare Terraform and provider requirements
- How to configure the Azure provider
- How to define variables, a resource, and outputs
- The standard file split used in real Terraform projects

Nothing else is included: no modules, remote state backend, or additional Azure resources.

## Prerequisites

- [tenv](https://tofuutils.github.io/tenv/) for Terraform version management — see [tenv.md](../../tenv.md)
- Terraform `>= 1.15.0` (pinned to **1.15.7** via `.terraform-version`)
- [azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) `~> 4.80` (latest: **4.80.0**)
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
azure/101-basic/
├── providers.tf   # Terraform version, provider requirements, and Azure provider
├── variables.tf   # Input variables
├── main.tf        # Resource definitions
├── outputs.tf     # Output values
└── README.md      # This file
```

| File | Responsibility |
|------|----------------|
| `providers.tf` | Pins Terraform and the `azurerm` provider, and configures Azure authentication |
| `variables.tf` | Defines configurable inputs with defaults |
| `main.tf` | Declares the infrastructure to create |
| `outputs.tf` | Exposes useful values after apply |

## What gets created

One Azure resource group:

| Resource | Name (default) | Location (default) |
|----------|----------------|--------------------|
| Resource group | `rg-learn-terraform-basic` | `Sweden Central` |

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `Sweden Central` | Azure region for the resource group |
| `resource_group_name` | `string` | `rg-learn-terraform-basic` | Name of the resource group |

Override defaults with a `.tfvars` file or command-line flags:

```bash
terraform apply -var="location=North Europe" -var="resource_group_name=rg-my-example"
```

Or create `terraform.tfvars` locally (this file is gitignored by default):

```hcl
location            = "North Europe"
resource_group_name = "rg-my-example"
```

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Name of the created resource group |
| `resource_group_id` | Azure resource ID of the resource group |

## Usage

From this directory:

```bash
cd azure/101-basic

# Download the Azure provider
terraform init

# Preview changes
terraform plan

# Create the resource group
terraform apply

# Remove the resource group when finished
terraform destroy
```

Confirm with `yes` when prompted, or use `-auto-approve` for non-interactive runs.

## Authentication

The Azure provider uses credentials from the Azure CLI by default. After `az login`, Terraform uses your active account.

For CI/CD or service principal authentication, set environment variables or use other [Azure provider authentication methods](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli).

## Next steps

Once you understand this layout, you can extend it by:

- Adding more resources inside the resource group
- Introducing a remote backend (for example Azure Storage)
- Splitting logic into modules
- Using separate `.tfvars` files per environment
