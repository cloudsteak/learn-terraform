# Azure Terraform Examples

## [101-basic](./101-basic/)

Minimal Terraform setup for Azure: one resource group and a standard project file layout.

→ [README](./101-basic/README.md)

## [201-remote-state](./201-remote-state/)

Simple remote state with Terraform's native `azurerm` backend in `backend.tf`. Bootstrap scripts create the Azure storage; use `terraform init`, not Terragrunt.

→ [README](./201-remote-state/README.md)
