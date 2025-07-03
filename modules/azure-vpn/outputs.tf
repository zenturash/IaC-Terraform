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

# Local Network Gateway Outputs
output "local_network_gateway_id" {
  description = "ID of the Local Network Gateway"
  value       = azurerm_local_network_gateway.on_premises.id
}

output "local_network_gateway_name" {
  description = "Name of the Local Network Gateway"
  value       = azurerm_local_network_gateway.on_premises.name
}

output "local_network_gateway_address" {
  description = "Gateway address of the Local Network Gateway"
  value       = azurerm_local_network_gateway.on_premises.gateway_address
}

output "local_network_address_space" {
  description = "Address space of the Local Network Gateway"
  value       = azurerm_local_network_gateway.on_premises.address_space
}

# VPN Connection Outputs
output "vpn_connection_id" {
  description = "ID of the VPN Connection"
  value       = azurerm_virtual_network_gateway_connection.vpn_connection.id
}

output "vpn_connection_name" {
  description = "Name of the VPN Connection"
  value       = azurerm_virtual_network_gateway_connection.vpn_connection.name
}

output "vpn_connection_status" {
  description = "Status of the VPN Connection (check Azure portal for actual status)"
  value       = "Check Azure portal for connection status"
}

# BGP Information (if enabled)
output "bgp_settings" {
  description = "BGP settings of the VPN Gateway (if BGP is enabled)"
  value = var.enable_bgp ? {
    asn         = azurerm_virtual_network_gateway.vpn_gateway.bgp_settings[0].asn
    peer_weight = azurerm_virtual_network_gateway.vpn_gateway.bgp_settings[0].peer_weight
  } : null
}

# Summary Information
output "vpn_summary" {
  description = "Summary of VPN configuration"
  value = {
    vpn_gateway_name      = azurerm_virtual_network_gateway.vpn_gateway.name
    vpn_gateway_public_ip = azurerm_public_ip.vpn_gateway.ip_address
    local_gateway_name    = azurerm_local_network_gateway.on_premises.name
    local_gateway_ip      = azurerm_local_network_gateway.on_premises.gateway_address
    connection_name       = azurerm_virtual_network_gateway_connection.vpn_connection.name
    connection_status     = "Check Azure portal for connection status"
    vpn_type             = azurerm_virtual_network_gateway.vpn_gateway.vpn_type
    sku                  = azurerm_virtual_network_gateway.vpn_gateway.sku
    bgp_enabled          = var.enable_bgp
  }
}
