# ============================================================================
# CORE VPN GATEWAY INFORMATION
# ============================================================================

# VPN Gateway Outputs
output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.vpn_gateway.id
}

output "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.vpn_gateway.name
}

output "vpn_gateway_public_ip" {
  description = "Public IP address of the VPN Gateway"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "vpn_gateway_public_ip_fqdn" {
  description = "FQDN of the VPN Gateway public IP"
  value       = azurerm_public_ip.vpn_gateway.fqdn
}

output "vpn_gateway_sku" {
  description = "SKU of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.vpn_gateway.sku
}

output "vpn_gateway_type" {
  description = "Type of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.vpn_gateway.vpn_type
}

output "vpn_gateway_generation" {
  description = "Generation of the VPN Gateway"
  value       = azurerm_virtual_network_gateway.vpn_gateway.generation
}

# ============================================================================
# LOCAL NETWORK GATEWAY INFORMATION (CONDITIONAL)
# ============================================================================

# Local Network Gateway Outputs
output "local_network_gateway_id" {
  description = "ID of the Local Network Gateway (null if not created)"
  value       = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].id : null
}

output "local_network_gateway_name" {
  description = "Name of the Local Network Gateway (null if not created)"
  value       = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].name : null
}

output "local_network_gateway_address" {
  description = "Gateway address of the Local Network Gateway (null if not created)"
  value       = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].gateway_address : null
}

output "local_network_address_space" {
  description = "Address space of the Local Network Gateway (null if not created)"
  value       = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].address_space : null
}

# ============================================================================
# VPN CONNECTION INFORMATION (CONDITIONAL)
# ============================================================================

# VPN Connection Outputs
output "vpn_connection_id" {
  description = "ID of the VPN Connection (null if not created)"
  value       = local.deploy_connection ? azurerm_virtual_network_gateway_connection.vpn_connection[0].id : null
}

output "vpn_connection_name" {
  description = "Name of the VPN Connection (null if not created)"
  value       = local.deploy_connection ? azurerm_virtual_network_gateway_connection.vpn_connection[0].name : null
}

output "vpn_connection_status" {
  description = "Status of the VPN Connection (check Azure portal for actual status)"
  value       = local.deploy_connection ? "Check Azure portal for connection status" : "No connection created"
}

# ============================================================================
# BGP INFORMATION (CONDITIONAL)
# ============================================================================

# BGP Information (if enabled)
output "bgp_settings" {
  description = "BGP settings of the VPN Gateway (null if BGP is disabled)"
  value = var.enable_bgp ? {
    asn         = azurerm_virtual_network_gateway.vpn_gateway.bgp_settings[0].asn
    peer_weight = azurerm_virtual_network_gateway.vpn_gateway.bgp_settings[0].peer_weight
    peering_addresses = azurerm_virtual_network_gateway.vpn_gateway.bgp_settings[0].peering_addresses
  } : null
}

# ============================================================================
# COMPREHENSIVE DEPLOYMENT SUMMARY
# ============================================================================

output "vpn_deployment_summary" {
  description = "Complete summary of VPN deployment with configuration details"
  value = {
    # Architecture Information
    deployment_mode = var.gateway_only_mode ? "gateway-only" : "full-site-to-site"
    
    # VPN Gateway Details
    vpn_gateway = {
      name       = azurerm_virtual_network_gateway.vpn_gateway.name
      id         = azurerm_virtual_network_gateway.vpn_gateway.id
      sku        = azurerm_virtual_network_gateway.vpn_gateway.sku
      generation = azurerm_virtual_network_gateway.vpn_gateway.generation
      type       = azurerm_virtual_network_gateway.vpn_gateway.vpn_type
      public_ip  = azurerm_public_ip.vpn_gateway.ip_address
      bgp_enabled = var.enable_bgp
    }
    
    # Local Network Gateway Details
    local_network_gateway = local.deploy_local_gateway ? {
      name            = azurerm_local_network_gateway.on_premises[0].name
      id              = azurerm_local_network_gateway.on_premises[0].id
      gateway_address = azurerm_local_network_gateway.on_premises[0].gateway_address
      address_space   = azurerm_local_network_gateway.on_premises[0].address_space
    } : null
    
    # VPN Connection Details
    vpn_connection = local.deploy_connection ? {
      name                = azurerm_virtual_network_gateway_connection.vpn_connection[0].name
      id                  = azurerm_virtual_network_gateway_connection.vpn_connection[0].id
      connection_protocol = azurerm_virtual_network_gateway_connection.vpn_connection[0].connection_protocol
      ipsec_policy_used   = var.vpn_connection.ipsec_policy != null && var.vpn_gateway_sku != "Basic"
    } : null
    
    # BGP Configuration
    bgp_configuration = var.enable_bgp ? {
      asn         = var.bgp_settings.asn
      peer_weight = var.bgp_settings.peer_weight
    } : null
    
    # Naming Information
    naming_configuration = {
      prefix            = var.resource_name_prefix
    }
    
    # Auto-generation Information
    auto_features = {
      auto_tagging_enabled = var.enable_auto_tagging
      validation_enabled   = var.validate_configuration_consistency
    }
  }
}

# ============================================================================
# CONNECTIVITY AND TROUBLESHOOTING GUIDE
# ============================================================================

output "connectivity_guide" {
  description = "Comprehensive guide for VPN connectivity and troubleshooting"
  value = {
    # Basic Information
    deployment_mode = var.gateway_only_mode ? "gateway-only" : "full-site-to-site"
    vpn_gateway_public_ip = azurerm_public_ip.vpn_gateway.ip_address
    
    # Connection Information
    connection_info = local.deploy_connection ? {
      azure_gateway_ip    = azurerm_public_ip.vpn_gateway.ip_address
      on_premises_ip      = var.local_network_gateway.gateway_address
      on_premises_networks = var.local_network_gateway.address_space
      connection_protocol = var.vpn_connection.connection_protocol
      ipsec_policy_custom = var.vpn_connection.ipsec_policy != null && var.vpn_gateway_sku != "Basic"
    } : {
      note = "Gateway-only mode - no connection configured"
    }
    
    # BGP Information
    bgp_info = var.enable_bgp ? {
      enabled     = true
      azure_asn   = var.bgp_settings.asn
      peer_weight = var.bgp_settings.peer_weight
      note        = "BGP is enabled - ensure on-premises device supports BGP"
    } : {
      enabled = false
      note    = "Static routing - configure routes manually on both sides"
    }
    
    # Configuration Notes
    configuration_notes = concat([
      "VPN Gateway SKU: ${var.vpn_gateway_sku} (${var.vpn_gateway_generation})",
      "VPN Type: ${var.vpn_type}",
      var.enable_bgp ? "✅ BGP enabled for dynamic routing" : "❌ BGP disabled - using static routing",
      var.vpn_connection != null && var.vpn_connection.ipsec_policy != null && var.vpn_gateway_sku != "Basic" ? "✅ Custom IPSec policy configured" : "❌ Using default IPSec policy"
    ], var.gateway_only_mode ? [
      "⚠️  Gateway-only mode - no site-to-site connection configured",
      "💡 Use this for multi-site scenarios or ExpressRoute coexistence"
    ] : [
      "✅ Full site-to-site VPN configured",
      "🔗 Connection established between Azure and on-premises"
    ])
    
    # Troubleshooting Information
    troubleshooting = {
      common_commands = [
        "az network vnet-gateway show --name ${azurerm_virtual_network_gateway.vpn_gateway.name} --resource-group ${var.resource_group_name}",
        local.deploy_connection ? "az network vpn-connection show --name ${local.vpn_connection_name} --resource-group ${var.resource_group_name}" : "No connection to check",
        var.enable_bgp ? "az network vnet-gateway list-bgp-peer-status --name ${azurerm_virtual_network_gateway.vpn_gateway.name} --resource-group ${var.resource_group_name}" : "BGP not enabled"
      ]
      
      common_issues = [
        "Gateway creation timeout - VPN Gateway creation can take 30-45 minutes",
        "Connection not established - Check shared key and on-premises configuration",
        "BGP not working - Verify ASN numbers and BGP configuration on both sides",
        "Routing issues - Check route tables and BGP advertisements",
        "Performance issues - Consider upgrading VPN Gateway SKU"
      ]
      
      monitoring_tips = [
        "Enable VPN Gateway diagnostics in Azure Monitor",
        "Monitor connection status in Azure portal",
        "Check effective routes on connected VMs",
        "Use Azure Network Watcher for connectivity testing",
        "Monitor BGP peer status if BGP is enabled"
      ]
    }
    
    # Security Considerations
    security_notes = [
      "Use strong shared keys (minimum 8 characters, recommended 20+)",
      "Consider custom IPSec policies for enhanced security",
      "Implement BGP authentication when possible",
      "Monitor VPN Gateway logs for security events",
      "Use Network Security Groups for additional traffic control",
      "Regularly rotate shared keys and certificates"
    ]
  }
}

# ============================================================================
# LEGACY COMPATIBILITY OUTPUTS
# ============================================================================

# Summary Information (backward compatibility)
output "vpn_summary" {
  description = "Basic summary of VPN configuration (legacy compatibility)"
  value = {
    vpn_gateway_name      = azurerm_virtual_network_gateway.vpn_gateway.name
    vpn_gateway_public_ip = azurerm_public_ip.vpn_gateway.ip_address
    local_gateway_name    = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].name : null
    local_gateway_ip      = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].gateway_address : null
    connection_name       = local.deploy_connection ? azurerm_virtual_network_gateway_connection.vpn_connection[0].name : null
    connection_status     = local.deploy_connection ? "Check Azure portal for connection status" : "No connection created"
    vpn_type             = azurerm_virtual_network_gateway.vpn_gateway.vpn_type
    sku                  = azurerm_virtual_network_gateway.vpn_gateway.sku
    bgp_enabled          = var.enable_bgp
  }
}

# ============================================================================
# TAGGING INFORMATION
# ============================================================================

output "applied_tags" {
  description = "Tags applied to all VPN resources"
  value       = local.common_tags
}

# ============================================================================
# RESOURCE NAMES FOR REFERENCE
# ============================================================================

output "resource_names" {
  description = "Names of all created VPN resources"
  value = {
    vpn_gateway_name      = azurerm_virtual_network_gateway.vpn_gateway.name
    public_ip_name        = azurerm_public_ip.vpn_gateway.name
    local_gateway_name    = local.deploy_local_gateway ? azurerm_local_network_gateway.on_premises[0].name : null
    connection_name       = local.deploy_connection ? azurerm_virtual_network_gateway_connection.vpn_connection[0].name : null
    naming_pattern        = "${var.resource_name_prefix}-{resource-type}"
  }
}

# ============================================================================
# DEPLOYMENT MODE INFORMATION
# ============================================================================

output "deployment_mode_info" {
  description = "Information about the deployment mode and created resources"
  value = {
    mode                  = var.gateway_only_mode ? "gateway-only" : "full-site-to-site"
    gateway_created       = true
    local_gateway_created = local.deploy_local_gateway
    connection_created    = local.deploy_connection
    bgp_enabled          = var.enable_bgp
    custom_ipsec_policy  = var.vpn_connection != null && var.vpn_connection.ipsec_policy != null && var.vpn_gateway_sku != "Basic"
    
    capabilities = {
      max_throughput = (
        var.vpn_gateway_sku == "Basic" ? "100 Mbps" : 
        var.vpn_gateway_sku == "VpnGw1" || var.vpn_gateway_sku == "VpnGw1AZ" ? "650 Mbps" :
        var.vpn_gateway_sku == "VpnGw2" || var.vpn_gateway_sku == "VpnGw2AZ" ? "1 Gbps" :
        var.vpn_gateway_sku == "VpnGw3" || var.vpn_gateway_sku == "VpnGw3AZ" ? "1.25 Gbps" :
        var.vpn_gateway_sku == "VpnGw4" || var.vpn_gateway_sku == "VpnGw4AZ" ? "5 Gbps" :
        var.vpn_gateway_sku == "VpnGw5" || var.vpn_gateway_sku == "VpnGw5AZ" ? "10 Gbps" : "Unknown"
      )
      
      max_tunnels = (
        var.vpn_gateway_sku == "Basic" ? 10 :
        contains(["VpnGw1", "VpnGw2", "VpnGw3", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ"], var.vpn_gateway_sku) ? 30 :
        contains(["VpnGw4", "VpnGw5", "VpnGw4AZ", "VpnGw5AZ"], var.vpn_gateway_sku) ? 100 : 0
      )
      
      bgp_support = var.vpn_gateway_sku != "Basic"
      zone_redundant = contains(["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"], var.vpn_gateway_sku)
    }
  }
}
