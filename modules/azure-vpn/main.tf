# ============================================================================
# RANDOM RESOURCES FOR AUTO-GENERATION
# ============================================================================

# Random ID for unique resource naming
resource "random_id" "main" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
}

# ============================================================================
# LOCAL VALUES FOR CONSISTENT NAMING AND CONFIGURATION
# ============================================================================

locals {
  # Generate unique suffix for resource names
  suffix = var.use_random_suffix ? "-${random_id.main[0].hex}" : ""
  
  # Smart resource names
  vpn_gateway_name = var.vpn_gateway_name != null ? var.vpn_gateway_name : "${var.resource_name_prefix}-gateway${local.suffix}"
  public_ip_name   = "pip-${local.vpn_gateway_name}"
  
  # Local network gateway name (if creating local gateway)
  local_gateway_name = var.local_network_gateway != null ? (
    var.local_network_gateway.name != null ? var.local_network_gateway.name : "${var.resource_name_prefix}-local-gateway${local.suffix}"
  ) : null
  
  # VPN connection name (if creating connection)
  vpn_connection_name = var.vpn_connection != null ? (
    var.vpn_connection.name != null ? var.vpn_connection.name : "${var.resource_name_prefix}-connection${local.suffix}"
  ) : null
  
  # Smart Public IP configuration based on VPN Gateway SKU
  public_ip_allocation = var.public_ip_allocation_method != null ? var.public_ip_allocation_method : (
    var.vpn_gateway_sku == "Basic" ? "Dynamic" : "Static"
  )
  public_ip_sku = var.public_ip_sku != null ? var.public_ip_sku : (
    var.vpn_gateway_sku == "Basic" ? "Basic" : "Standard"
  )
  
  # Determine deployment mode
  deploy_local_gateway = var.local_network_gateway != null && !var.gateway_only_mode
  deploy_connection    = var.vpn_connection != null && var.local_network_gateway != null && !var.gateway_only_mode
  
  # Enhanced auto-tagging
  base_tags = var.enable_auto_tagging ? {
    vpn_gateway_name      = local.vpn_gateway_name
    vpn_gateway_sku       = var.vpn_gateway_sku
    vpn_gateway_generation = var.vpn_gateway_generation
    vpn_type              = var.vpn_type
    bgp_enabled           = var.enable_bgp
    bgp_asn               = var.enable_bgp ? var.bgp_settings.asn : null
    deployment_mode       = var.gateway_only_mode ? "gateway-only" : "full-site-to-site"
    local_gateway_created = local.deploy_local_gateway
    connection_created    = local.deploy_connection
    creation_date         = formatdate("YYYY-MM-DD", timestamp())
    creation_time         = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method       = "OpenTofu"
    random_suffix_used    = var.use_random_suffix
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
}

# ============================================================================
# VPN GATEWAY RESOURCES
# ============================================================================

# Public IP for VPN Gateway
# Note: As of Dec 2023, new VPN Gateways require Standard SKU public IPs (except Basic VPN Gateway)
# Basic SKU public IPs are being retired in September 2025
resource "azurerm_public_ip" "vpn_gateway" {
  name                = local.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = local.public_ip_allocation
  sku                 = local.public_ip_sku
  
  tags = local.common_tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = local.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = var.gateway_type
  vpn_type = var.vpn_type

  active_active = var.active_active
  enable_bgp    = var.enable_bgp
  sku           = var.vpn_gateway_sku
  generation    = var.vpn_gateway_generation

  ip_configuration {
    name                          = var.ip_configuration_name
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = var.private_ip_address_allocation
    subnet_id                     = var.gateway_subnet_id
  }

  dynamic "bgp_settings" {
    for_each = var.enable_bgp ? [1] : []
    content {
      asn         = var.bgp_settings.asn
      peer_weight = var.bgp_settings.peer_weight
    }
  }

  tags = local.common_tags

  # VPN Gateway creation can take 30-45 minutes
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# ============================================================================
# LOCAL NETWORK GATEWAY (CONDITIONAL)
# ============================================================================

# Local Network Gateway (represents on-premises network)
resource "azurerm_local_network_gateway" "on_premises" {
  count = local.deploy_local_gateway ? 1 : 0
  
  name                = local.local_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.local_network_gateway.gateway_address
  address_space       = var.local_network_gateway.address_space
  
  tags = local.common_tags
}

# ============================================================================
# VPN CONNECTION (CONDITIONAL)
# ============================================================================

# VPN Connection between Azure VPN Gateway and Local Network Gateway
resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  count = local.deploy_connection ? 1 : 0
  
  name                = local.vpn_connection_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.on_premises[0].id

  shared_key          = var.vpn_connection.shared_key
  connection_protocol = var.vpn_connection.connection_protocol

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

  tags = local.common_tags

  # Ensure VPN Gateway and Local Network Gateway are fully created before creating connection
  depends_on = [
    azurerm_virtual_network_gateway.vpn_gateway,
    azurerm_local_network_gateway.on_premises
  ]
}
