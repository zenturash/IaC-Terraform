# Hub to Spoke Peering Information
output "hub_to_spoke_peering_ids" {
  description = "Map of hub to spoke peering IDs"
  value       = { for k, v in azurerm_virtual_network_peering.hub_to_spoke : k => v.id }
}

output "hub_to_spoke_peering_names" {
  description = "Map of hub to spoke peering names"
  value       = { for k, v in azurerm_virtual_network_peering.hub_to_spoke : k => v.name }
}

# Spoke to Hub Peering Information
output "spoke_to_hub_peering_ids" {
  description = "Map of spoke to hub peering IDs"
  value       = { for k, v in azurerm_virtual_network_peering.spoke_to_hub : k => v.id }
}

output "spoke_to_hub_peering_names" {
  description = "Map of spoke to hub peering names"
  value       = { for k, v in azurerm_virtual_network_peering.spoke_to_hub : k => v.name }
}

# Peering Status
output "peering_status" {
  description = "Status of all peering connections"
  value = {
    hub_to_spoke = { for k, v in azurerm_virtual_network_peering.hub_to_spoke : k => v.virtual_network_peering_state }
    spoke_to_hub = { for k, v in azurerm_virtual_network_peering.spoke_to_hub : k => v.virtual_network_peering_state }
  }
}

# Summary Information
output "peering_summary" {
  description = "Summary of all peering connections"
  value = {
    total_connections = length(var.peering_connections)
    hub_vnet_name     = var.hub_vnet_name
    spoke_vnets       = keys(var.peering_connections)
  }
}
