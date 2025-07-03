# Resource Group Information
output "networking_resource_group_name" {
  description = "Name of the networking resource group"
  value       = azurerm_resource_group.networking.name
}

output "networking_resource_group_id" {
  description = "ID of the networking resource group"
  value       = azurerm_resource_group.networking.id
}

# Virtual Network Information
output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

# Subnet Information
output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "List of subnet names"
  value       = keys(azurerm_subnet.subnets)
}

output "subnets" {
  description = "Complete subnet information"
  value = {
    for k, v in azurerm_subnet.subnets : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
    }
  }
}

# Backward compatibility - returns the first subnet for single subnet scenarios
output "subnet_id" {
  description = "ID of the first subnet (for backward compatibility)"
  value       = length(azurerm_subnet.subnets) > 0 ? values(azurerm_subnet.subnets)[0].id : null
}

output "subnet_name" {
  description = "Name of the first subnet (for backward compatibility)"
  value       = length(azurerm_subnet.subnets) > 0 ? values(azurerm_subnet.subnets)[0].name : null
}
