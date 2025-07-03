# Resource Group Information
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region where resources were created"
  value       = azurerm_resource_group.main.location
}

# Virtual Machine Information
output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_size" {
  description = "Size of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.size
}

# Network Information
output "private_ip_address" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.main.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.main.id
}


# Connection Information
output "rdp_connection_string" {
  description = "RDP connection string (if public IP is enabled)"
  value       = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "Public IP not enabled - use private IP: ${azurerm_network_interface.main.private_ip_address}"
}

output "admin_username" {
  description = "Administrator username for the virtual machine"
  value       = azurerm_windows_virtual_machine.main.admin_username
}

# Tags Information
output "tags" {
  description = "Tags applied to the VM"
  value       = azurerm_windows_virtual_machine.main.tags
}

# NSG Information
output "nsg_id" {
  description = "ID of the Network Security Group (if created)"
  value       = var.enable_public_ip ? azurerm_network_security_group.main[0].id : null
}

output "nsg_name" {
  description = "Name of the Network Security Group (if created)"
  value       = var.enable_public_ip ? azurerm_network_security_group.main[0].name : null
}

output "nsg_rules" {
  description = "List of NSG rules applied"
  value       = var.nsg_rules
}
