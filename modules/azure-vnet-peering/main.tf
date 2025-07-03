# VNet Peering from Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub
  for_each = var.peering_connections

  name                      = "peer-${var.hub_vnet_name}-to-${each.key}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = each.value.spoke_vnet_id

  allow_virtual_network_access = var.peering_config.allow_virtual_network_access
  allow_forwarded_traffic      = var.peering_config.allow_forwarded_traffic
  allow_gateway_transit        = var.peering_config.allow_gateway_transit
  use_remote_gateways         = false  # Hub provides gateway, doesn't use remote

  depends_on = [var.hub_vnet_id]
}

# VNet Peering from Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  provider = azurerm.spoke
  for_each = var.peering_connections

  name                      = "peer-${each.key}-to-${var.hub_vnet_name}"
  resource_group_name       = each.value.spoke_resource_group_name
  virtual_network_name      = each.value.spoke_vnet_name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = var.peering_config.allow_virtual_network_access
  allow_forwarded_traffic      = var.peering_config.allow_forwarded_traffic
  allow_gateway_transit        = false  # Spoke doesn't provide gateway
  use_remote_gateways         = var.peering_config.use_remote_gateways

  depends_on = [var.hub_vnet_id]
}
