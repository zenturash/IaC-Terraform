# ============================================================================
# RESOURCE GROUP OUTPUTS
# ============================================================================

output "networking_resource_group_name" {
  description = "Name of the networking resource group"
  value       = azurerm_resource_group.networking.name
}

output "networking_resource_group_id" {
  description = "ID of the networking resource group"
  value       = azurerm_resource_group.networking.id
}

output "networking_resource_group_location" {
  description = "Location of the networking resource group"
  value       = azurerm_resource_group.networking.location
}

# ============================================================================
# VIRTUAL NETWORK OUTPUTS
# ============================================================================

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

output "vnet_location" {
  description = "Location of the virtual network"
  value       = azurerm_virtual_network.main.location
}

output "vnet_resource_group_name" {
  description = "Resource group name of the virtual network"
  value       = azurerm_virtual_network.main.resource_group_name
}

output "vnet_dns_servers" {
  description = "DNS servers configured for the virtual network"
  value       = azurerm_virtual_network.main.dns_servers
}

output "vnet_guid" {
  description = "GUID of the virtual network"
  value       = azurerm_virtual_network.main.guid
}

# ============================================================================
# SUBNET OUTPUTS
# ============================================================================

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "List of subnet names"
  value       = keys(azurerm_subnet.subnets)
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes }
}

output "subnets" {
  description = "Complete subnet information"
  value = {
    for k, v in azurerm_subnet.subnets : k => {
      id                     = v.id
      name                   = v.name
      address_prefixes       = v.address_prefixes
      service_endpoints      = v.service_endpoints
      private_endpoint_network_policies_enabled = v.private_endpoint_network_policies_enabled
      private_link_service_network_policies_enabled = v.private_link_service_network_policies_enabled
    }
  }
}

# ============================================================================
# GATEWAY SUBNET OUTPUTS
# ============================================================================

output "gateway_subnet_id" {
  description = "ID of the GatewaySubnet (if created)"
  value       = var.create_gateway_subnet ? azurerm_subnet.subnets["GatewaySubnet"].id : null
}

output "gateway_subnet_address_prefix" {
  description = "Address prefix of the GatewaySubnet (if created)"
  value       = var.create_gateway_subnet ? azurerm_subnet.subnets["GatewaySubnet"].address_prefixes[0] : null
}

# ============================================================================
# BACKWARD COMPATIBILITY OUTPUTS
# ============================================================================

output "subnet_id" {
  description = "ID of the first subnet (for backward compatibility)"
  value       = length(azurerm_subnet.subnets) > 0 ? values(azurerm_subnet.subnets)[0].id : null
}

output "subnet_name" {
  description = "Name of the first subnet (for backward compatibility)"
  value       = length(azurerm_subnet.subnets) > 0 ? values(azurerm_subnet.subnets)[0].name : null
}

# ============================================================================
# NETWORK SECURITY GROUP OUTPUTS
# ============================================================================

output "created_nsgs" {
  description = "Map of subnet names to their created NSG information"
  value = {
    for k, v in azurerm_network_security_group.subnet_nsgs : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "created_nsg_ids" {
  description = "Map of subnet names to their created NSG IDs"
  value       = { for k, v in azurerm_network_security_group.subnet_nsgs : k => v.id }
}

output "created_nsg_names" {
  description = "Map of subnet names to their created NSG names"
  value       = { for k, v in azurerm_network_security_group.subnet_nsgs : k => v.name }
}

output "nsg_rules_count" {
  description = "Map of subnet names to their NSG rules count"
  value = {
    for subnet_name in keys(var.create_subnet_nsgs) : subnet_name => length(lookup(var.subnet_nsg_rules, subnet_name, []))
  }
}

# ============================================================================
# NETWORK SECURITY GROUP ASSOCIATION OUTPUTS
# ============================================================================

output "created_nsg_associations" {
  description = "Map of subnet names to their created NSG association IDs"
  value       = { for k, v in azurerm_subnet_network_security_group_association.created_nsg_associations : k => v.id }
}

output "external_nsg_associations" {
  description = "Map of subnet names to their external NSG IDs"
  value       = var.subnet_nsg_associations
}

output "external_nsg_association_ids" {
  description = "Map of external NSG association resource IDs"
  value       = { for k, v in azurerm_subnet_network_security_group_association.external_nsg_associations : k => v.id }
}

output "all_nsg_associations" {
  description = "Combined map of all NSG associations (created and external)"
  value = merge(
    { for k, v in azurerm_network_security_group.subnet_nsgs : k => v.id },
    var.subnet_nsg_associations
  )
}

# ============================================================================
# ROUTE TABLE ASSOCIATION OUTPUTS
# ============================================================================

output "route_table_associations" {
  description = "Map of subnet names to their associated route table IDs"
  value       = var.subnet_route_table_associations
}

output "route_table_association_ids" {
  description = "Map of route table association resource IDs"
  value       = { for k, v in azurerm_subnet_route_table_association.route_table_associations : k => v.id }
}

# ============================================================================
# CONFIGURATION SUMMARY OUTPUTS
# ============================================================================

output "network_summary" {
  description = "Comprehensive summary of the network configuration"
  value = {
    # Basic Information
    vnet_name           = azurerm_virtual_network.main.name
    vnet_id             = azurerm_virtual_network.main.id
    vnet_cidr           = var.vnet_cidr
    location            = azurerm_virtual_network.main.location
    resource_group      = azurerm_resource_group.networking.name
    
    # Subnet Information
    subnet_count        = length(azurerm_subnet.subnets)
    subnet_names        = keys(azurerm_subnet.subnets)
    gateway_subnet      = var.create_gateway_subnet
    
    # Advanced Configuration
    dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : ["Azure Default"]
    ddos_protection     = var.ddos_protection_plan_id != null
    flow_timeout        = var.flow_timeout_in_minutes
    bgp_community       = var.bgp_community
    encryption          = var.encryption
    
    # Service Configuration
    service_endpoints_configured = length(var.subnet_service_endpoints) > 0
    delegations_configured       = length(var.subnet_delegations) > 0
    nsg_associations            = length(var.subnet_nsg_associations)
    route_table_associations    = length(var.subnet_route_table_associations)
  }
}

# ============================================================================
# SERVICE ENDPOINTS OUTPUTS
# ============================================================================

output "subnet_service_endpoints" {
  description = "Map of subnet names to their configured service endpoints"
  value       = var.subnet_service_endpoints
}

output "subnet_delegations" {
  description = "Map of subnet names to their delegation configurations"
  value       = var.subnet_delegations
}

# ============================================================================
# CALCULATED VALUES OUTPUTS
# ============================================================================

output "calculated_subnet_cidrs" {
  description = "Map of subnet names to their calculated CIDR blocks"
  value       = { for k, v in local.subnets : k => v.cidr }
}

output "available_ip_addresses" {
  description = "Map of subnet names to their available IP address count (approximate)"
  value = {
    for k, v in local.subnets : k => pow(2, 32 - tonumber(split("/", v.cidr)[1])) - 5  # -5 for Azure reserved IPs
  }
}

# ============================================================================
# TAGS OUTPUTS
# ============================================================================

output "applied_tags" {
  description = "All tags applied to the networking resources"
  value       = local.common_tags
}

output "auto_tags_enabled" {
  description = "Whether automatic tagging is enabled"
  value       = var.enable_auto_tagging
}

# ============================================================================
# DEPLOYMENT INFORMATION
# ============================================================================

output "deployment_info" {
  description = "Information about the network deployment"
  value = {
    creation_date       = formatdate("YYYY-MM-DD", timestamp())
    creation_method     = "OpenTofu"
    module_version      = "generalized"
    total_subnets       = length(azurerm_subnet.subnets)
    gateway_enabled     = var.create_gateway_subnet
    advanced_features   = {
      dns_servers       = length(var.dns_servers) > 0
      ddos_protection   = var.ddos_protection_plan_id != null
      service_endpoints = length(var.subnet_service_endpoints) > 0
      delegations       = length(var.subnet_delegations) > 0
      nsg_associations  = length(var.subnet_nsg_associations) > 0
      route_associations = length(var.subnet_route_table_associations) > 0
    }
  }
}
