output "resource_group_name" {
  description = "Name of the created resource group."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Azure resource ID of the created resource group."
  value       = module.resource_group.id
}
