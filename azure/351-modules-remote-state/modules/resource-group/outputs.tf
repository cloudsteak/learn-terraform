output "name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Azure resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}
