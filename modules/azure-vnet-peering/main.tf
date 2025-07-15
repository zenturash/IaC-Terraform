# ============================================================================
# RANDOM RESOURCES FOR AUTO-GENERATION
# ============================================================================

# Random ID for unique peering naming
resource "random_id" "main" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
}

# ============================================================================
# LOCAL VALUES FOR CONSISTENT NAMING AND CONFIGURATION
# ============================================================================

locals {
  # Generate unique suffix for peering names
  suffix = var.use_random_suffix ? "-${random_id.main[0].hex}" : ""
  
  # Smart peering names
  hub_to_spoke_names = {
    for k, v in var.peering_connections : k => 
      "${var.peering_name_prefix}-${var.hub_vnet_name}-to-${k}${local.suffix}"
  }
  
  spoke_to_hub_names = {
    for k, v in var.peering_connections : k => 
      "${var.peering_name_prefix}-${k}-to-${var.hub_vnet_name}${local.suffix}"
  }
  
  # Enhanced auto-tagging
  base_tags = var.enable_auto_tagging ? {
    peering_type           = "hub-spoke"
    hub_vnet              = var.hub_vnet_name
    spoke_count           = length(var.peering_connections)
    gateway_transit       = var.peering_config.allow_gateway_transit
    forwarded_traffic     = var.peering_config.allow_forwarded_traffic
    virtual_network_access = var.peering_config.allow_virtual_network_access
    use_remote_gateways   = var.peering_config.use_remote_gateways
    creation_date         = formatdate("YYYY-MM-DD", timestamp())
    creation_time         = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method       = "OpenTofu"
    random_suffix_used    = var.use_random_suffix
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
}

# ============================================================================
# VNET PEERING RESOURCES
# ============================================================================

# VNet Peering from Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub
  for_each = var.peering_connections

  name                      = local.hub_to_spoke_names[each.key]
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

  name                      = local.spoke_to_hub_names[each.key]
  resource_group_name       = each.value.spoke_resource_group_name
  virtual_network_name      = each.value.spoke_vnet_name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = var.peering_config.allow_virtual_network_access
  allow_forwarded_traffic      = var.peering_config.allow_forwarded_traffic
  allow_gateway_transit        = false  # Spoke doesn't provide gateway
  use_remote_gateways         = var.peering_config.use_remote_gateways

  depends_on = [var.hub_vnet_id]
}
