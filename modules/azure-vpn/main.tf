# Public IP for VPN Gateway
# Note: As of Dec 2023, new VPN Gateways require Standard SKU public IPs (except Basic VPN Gateway)
# Basic SKU public IPs are being retired in September 2025
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-${var.vpn_gateway_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.vpn_gateway_sku == "Basic" ? "Dynamic" : "Static"  # Basic requires Dynamic, Standard requires Static
  sku                 = var.vpn_gateway_sku == "Basic" ? "Basic" : "Standard"
  tags                = var.tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = var.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = var.vpn_type

  active_active = false
  enable_bgp    = var.enable_bgp
  sku           = var.vpn_gateway_sku
  generation    = var.vpn_gateway_generation

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  dynamic "bgp_settings" {
    for_each = var.enable_bgp ? [1] : []
    content {
      asn         = var.bgp_settings.asn
      peer_weight = var.bgp_settings.peer_weight
    }
  }

  tags = var.tags

  # VPN Gateway creation can take 30-45 minutes
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# Local Network Gateway (represents on-premises network)
resource "azurerm_local_network_gateway" "on_premises" {
  name                = var.local_network_gateway.name
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.local_network_gateway.gateway_address
  address_space       = var.local_network_gateway.address_space
  tags                = var.tags
}

# VPN Connection between Azure VPN Gateway and Local Network Gateway
resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  name                = var.vpn_connection.name
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.on_premises.id

  shared_key                 = var.vpn_connection.shared_key
  connection_protocol        = var.vpn_connection.connection_protocol

  # Custom IPSec policy (only supported on Standard SKU or higher)
  dynamic "ipsec_policy" {
    for_each = var.vpn_connection.ipsec_policy != null && var.vpn_gateway_sku != "Basic" ? [var.vpn_connection.ipsec_policy] : []
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_lifetime      = ipsec_policy.value.sa_lifetime
    }
  }

  tags = var.tags

  # Ensure VPN Gateway is fully created before creating connection
  depends_on = [azurerm_virtual_network_gateway.vpn_gateway]
}
