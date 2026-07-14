output "resource_group_name" {
  description = "Name of the workload resource group."
  value       = azurerm_resource_group.workload.name
}

output "resource_group_id" {
  description = "Azure resource ID of the workload resource group."
  value       = azurerm_resource_group.workload.id
}
