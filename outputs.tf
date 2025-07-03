# Networking Information
output "networking_resource_group_name" {
  description = "Name of the networking resource group"
  value       = module.networking.networking_resource_group_name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "subnet_names" {
  description = "List of all subnet names"
  value       = module.networking.subnet_names
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.networking.subnet_ids
}

output "subnets" {
  description = "Complete information about all subnets"
  value       = module.networking.subnets
}

# Virtual Machines Information
output "virtual_machines" {
  description = "Information about all created virtual machines"
  value = {
    for vm_name, vm_module in module.vms : vm_name => {
      vm_id                = vm_module.vm_id
      vm_name              = vm_module.vm_name
      vm_size              = vm_module.vm_size
      resource_group_name  = vm_module.resource_group_name
      location             = vm_module.location
      private_ip_address   = vm_module.private_ip_address
      public_ip_address    = vm_module.public_ip_address
      rdp_connection_string = vm_module.rdp_connection_string
      admin_username       = vm_module.admin_username
      tags                 = vm_module.tags
    }
  }
}

# VM Resource Groups
output "vm_resource_groups" {
  description = "Map of VM names to their resource group names"
  value = {
    for vm_name, vm_module in module.vms : vm_name => vm_module.resource_group_name
  }
}

# VM IP Addresses
output "vm_private_ips" {
  description = "Map of VM names to their private IP addresses"
  value = {
    for vm_name, vm_module in module.vms : vm_name => vm_module.private_ip_address
  }
}

output "vm_public_ips" {
  description = "Map of VM names to their public IP addresses (if enabled)"
  value = {
    for vm_name, vm_module in module.vms : vm_name => vm_module.public_ip_address
  }
}

# RDP Connection Strings
output "rdp_connections" {
  description = "Map of VM names to their RDP connection strings"
  value = {
    for vm_name, vm_module in module.vms : vm_name => vm_module.rdp_connection_string
  }
}

# Summary
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    total_vms = length(var.virtual_machines)
    total_subnets = length(var.subnet_names)
    vms_with_public_ip = length([
      for vm_name, vm_config in var.virtual_machines : vm_name
      if vm_config.enable_public_ip
    ])
    resource_groups = length(distinct([
      for vm_name, vm_config in var.virtual_machines : vm_config.resource_group_name
    ])) + 1  # +1 for networking RG
  }
}
