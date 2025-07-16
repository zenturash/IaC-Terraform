# ============================================================================
# CORE PEERING INFORMATION
# ============================================================================

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

# ============================================================================
# PEERING STATUS AND HEALTH
# ============================================================================

# Peering Status
output "peering_status" {
  description = "Status of all VNet peering connections"
  value = {
    hub_to_spoke = { for k, v in azurerm_virtual_network_peering.hub_to_spoke : k => "Check Azure portal for peering status" }
    spoke_to_hub = { for k, v in azurerm_virtual_network_peering.spoke_to_hub : k => "Check Azure portal for peering status" }
  }
}

# All Peering Names (for reference)
output "all_peering_names" {
  description = "All peering connection names created"
  value = {
    hub_to_spoke = local.hub_to_spoke_names
    spoke_to_hub = local.spoke_to_hub_names
  }
}

# ============================================================================
# COMPREHENSIVE DEPLOYMENT SUMMARY
# ============================================================================

output "peering_deployment_summary" {
  description = "Complete summary of peering deployment with configuration details"
  value = {
    # Architecture Information
    architecture        = "hub-spoke"
    hub_vnet           = var.hub_vnet_name
    total_peerings     = length(var.peering_connections) * 2  # Bidirectional
    spoke_vnets        = keys(var.peering_connections)
    
    # Configuration Details
    peering_configuration = {
      virtual_network_access = var.peering_config.allow_virtual_network_access
      forwarded_traffic     = var.peering_config.allow_forwarded_traffic
      gateway_transit       = var.peering_config.allow_gateway_transit
      use_remote_gateways   = var.peering_config.use_remote_gateways
    }
    
    # Naming Information
    naming_configuration = {
      prefix            = var.peering_name_prefix
      random_suffix     = var.use_random_suffix
      suffix_used       = var.use_random_suffix ? local.suffix : "none"
    }
    
    # Peering Names
    peering_names = {
      hub_to_spoke = local.hub_to_spoke_names
      spoke_to_hub = local.spoke_to_hub_names
    }
    
    # Auto-generation Information
    auto_features = {
      auto_tagging_enabled = var.enable_auto_tagging
      random_suffix_used   = var.use_random_suffix
      validation_enabled   = var.validate_gateway_consistency
    }
  }
}

# ============================================================================
# CONNECTIVITY GUIDE
# ============================================================================

output "connectivity_guide" {
  description = "Comprehensive guide for understanding peering connectivity and troubleshooting"
  value = {
    # Basic Information
    hub_vnet = var.hub_vnet_name
    architecture = "hub-spoke"
    
    # Connectivity Matrix
    connectivity_matrix = {
      for spoke in keys(var.peering_connections) : spoke => {
        to_hub = "Enabled"
        from_hub = "Enabled"
        gateway_access = var.peering_config.use_remote_gateways ? "Via Hub Gateway" : "No Gateway Access"
        traffic_forwarding = var.peering_config.allow_forwarded_traffic ? "Enabled (can route via hub)" : "Disabled (direct only)"
        virtual_network_access = var.peering_config.allow_virtual_network_access ? "Enabled" : "Disabled"
      }
    }
    
    # Configuration Explanations
    configuration_notes = [
      var.peering_config.allow_virtual_network_access ? "✅ VMs can communicate between hub and spokes" : "❌ VM communication blocked between hub and spokes",
      var.peering_config.allow_forwarded_traffic ? "✅ Traffic can be forwarded through hub (enables spoke-to-spoke via hub routing)" : "❌ Only direct traffic allowed (spokes are isolated from each other)",
      var.peering_config.allow_gateway_transit ? "✅ Hub provides gateway services (VPN/ExpressRoute) to spokes" : "❌ No gateway services provided by hub",
      var.peering_config.use_remote_gateways ? "✅ Spokes use hub gateway for external connectivity" : "❌ Spokes do not use hub gateway"
    ]
    
    # Troubleshooting Information
    troubleshooting = {
      peering_state_check = "Use 'az network vnet peering list' to check peering status"
      connectivity_test = "Test VM-to-VM connectivity to verify peering is working"
      routing_check = "Check effective routes on VM NICs to verify gateway transit"
      common_issues = [
        "Peering state 'Disconnected' - Check if both directions are created",
        "No connectivity - Verify NSGs and route tables",
        "Gateway transit not working - Ensure hub has VPN/ExpressRoute Gateway"
      ]
    }
    
    # Security Considerations
    security_notes = [
      "Peering connections are not transitive - spokes cannot communicate directly",
      "Use NSGs and route tables for additional traffic control",
      "Monitor peering connections for unexpected traffic patterns",
      "Consider Azure Firewall in hub for centralized security"
    ]
  }
}

# ============================================================================
# LEGACY COMPATIBILITY OUTPUTS
# ============================================================================

# Summary Information (backward compatibility)
output "peering_summary" {
  description = "Basic summary of all peering connections (legacy compatibility)"
  value = {
    total_connections = length(var.peering_connections)
    hub_vnet_name     = var.hub_vnet_name
    spoke_vnets       = keys(var.peering_connections)
  }
}

# ============================================================================
# TAGGING INFORMATION
# ============================================================================

output "applied_tags" {
  description = "Tags that would be applied to resources (peering resources don't support tags)"
  value       = local.common_tags
}

# ============================================================================
# RESOURCE NAMES FOR REFERENCE
# ============================================================================

output "resource_names" {
  description = "Names of all created peering resources"
  value = {
    hub_to_spoke_peerings = values(local.hub_to_spoke_names)
    spoke_to_hub_peerings = values(local.spoke_to_hub_names)
    naming_pattern = "${var.peering_name_prefix}-{vnet1}-to-{vnet2}${var.use_random_suffix ? "-{random}" : ""}"
  }
}
