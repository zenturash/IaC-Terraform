# ============================================================================
# REQUIRED VARIABLES (Minimal Requirements)
# ============================================================================

variable "resource_group_name" {
  description = "Name of the resource group for VPN resources"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region where VPN resources will be created"
  type        = string
  default     = "West Europe"
  
  validation {
    condition     = length(var.location) > 0
    error_message = "Location cannot be empty."
  }
}

variable "gateway_subnet_id" {
  description = "ID of the GatewaySubnet where VPN Gateway will be deployed"
  type        = string
  
  validation {
    condition     = length(var.gateway_subnet_id) > 0 && can(regex(".*GatewaySubnet$", var.gateway_subnet_id))
    error_message = "Gateway subnet ID must be valid and end with 'GatewaySubnet'."
  }
}

# ============================================================================
# VPN GATEWAY CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "vpn_gateway_name" {
  description = "Name of the VPN Gateway. If null, will auto-generate with random suffix"
  type        = string
  default     = null
  
  validation {
    condition     = var.vpn_gateway_name == null || (length(var.vpn_gateway_name) > 0 && length(var.vpn_gateway_name) <= 80)
    error_message = "VPN Gateway name must be between 1 and 80 characters when specified."
  }
}

variable "vpn_gateway_sku" {
  description = "SKU of the VPN Gateway"
  type        = string
  default     = "VpnGw1"
  
  validation {
    condition = contains([
      "Basic", "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5",
      "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"
    ], var.vpn_gateway_sku)
    error_message = "VPN Gateway SKU must be a valid Azure VPN Gateway SKU."
  }
}

variable "vpn_gateway_generation" {
  description = "Generation of the VPN Gateway"
  type        = string
  default     = "Generation1"
  
  validation {
    condition     = contains(["Generation1", "Generation2"], var.vpn_gateway_generation)
    error_message = "VPN Gateway generation must be Generation1 or Generation2."
  }
}

variable "vpn_type" {
  description = "Type of VPN (RouteBased or PolicyBased)"
  type        = string
  default     = "RouteBased"
  
  validation {
    condition     = contains(["RouteBased", "PolicyBased"], var.vpn_type)
    error_message = "VPN type must be RouteBased or PolicyBased."
  }
}

variable "enable_bgp" {
  description = "Enable BGP for the VPN Gateway"
  type        = bool
  default     = false
}

variable "bgp_settings" {
  description = "BGP settings for the VPN Gateway (only used if enable_bgp is true)"
  type = object({
    asn         = optional(number, 65515)
    peer_weight = optional(number, 0)
  })
  default = {
    asn         = 65515
    peer_weight = 0
  }
  
  validation {
    condition     = var.bgp_settings.asn >= 1 && var.bgp_settings.asn <= 4294967295
    error_message = "BGP ASN must be between 1 and 4294967295."
  }
  
  validation {
    condition     = var.bgp_settings.peer_weight >= 0 && var.bgp_settings.peer_weight <= 100
    error_message = "BGP peer weight must be between 0 and 100."
  }
}

# ============================================================================
# LOCAL NETWORK GATEWAY CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "local_network_gateway" {
  description = "Configuration for the local network gateway (on-premises). If null, no local gateway or connection will be created"
  type = object({
    name               = optional(string, null)  # Auto-generate if null
    gateway_address    = string                  # Public IP of on-premises VPN device
    address_space      = list(string)           # On-premises network CIDRs
  })
  default = null
  
  validation {
    condition = var.local_network_gateway == null || (
      var.local_network_gateway.gateway_address != null &&
      length(var.local_network_gateway.address_space) > 0
    )
    error_message = "When local_network_gateway is specified, gateway_address and address_space are required."
  }
  
  validation {
    condition = var.local_network_gateway == null || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.local_network_gateway.gateway_address))
    error_message = "Gateway address must be a valid IPv4 address."
  }
  
  validation {
    condition = var.local_network_gateway == null || alltrue([
      for cidr in var.local_network_gateway.address_space : can(cidrhost(cidr, 0))
    ])
    error_message = "All address spaces must be valid CIDR blocks."
  }
}

# ============================================================================
# VPN CONNECTION CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "vpn_connection" {
  description = "Configuration for the VPN connection. If null, no connection will be created (gateway-only mode)"
  type = object({
    name                = optional(string, null)  # Auto-generate if null
    shared_key          = string                  # Pre-shared key for VPN connection
    connection_protocol = optional(string, "IKEv2")
    ipsec_policy = optional(object({
      dh_group         = optional(string, "DHGroup14")
      ike_encryption   = optional(string, "AES256")
      ike_integrity    = optional(string, "SHA256")
      ipsec_encryption = optional(string, "AES256")
      ipsec_integrity  = optional(string, "SHA256")
      pfs_group        = optional(string, "PFS14")
      sa_lifetime      = optional(number, 3600)
    }), null)
  })
  default   = null
  sensitive = true
  
  validation {
    condition = var.vpn_connection == null || length(var.vpn_connection.shared_key) >= 8
    error_message = "VPN connection shared key must be at least 8 characters long."
  }
  
  validation {
    condition = var.vpn_connection == null || contains(["IKEv1", "IKEv2"], var.vpn_connection.connection_protocol)
    error_message = "Connection protocol must be IKEv1 or IKEv2."
  }
  
  validation {
    condition = var.vpn_connection == null || var.vpn_connection.ipsec_policy == null || (
      var.vpn_connection.ipsec_policy.sa_lifetime >= 300 && var.vpn_connection.ipsec_policy.sa_lifetime <= 172800
    )
    error_message = "IPSec SA lifetime must be between 300 and 172800 seconds."
  }
}

# ============================================================================
# NAMING CONFIGURATION
# ============================================================================

variable "resource_name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "vpn"
  
  validation {
    condition     = length(var.resource_name_prefix) > 0 && length(var.resource_name_prefix) <= 20
    error_message = "Resource name prefix must be between 1 and 20 characters."
  }
}

variable "use_random_suffix" {
  description = "Add random suffix to resource names for uniqueness across deployments"
  type        = bool
  default     = true
}

# ============================================================================
# TAGGING CONFIGURATION
# ============================================================================

variable "tags" {
  description = "Tags to apply to all VPN resources"
  type        = map(string)
  default     = {}
}

variable "enable_auto_tagging" {
  description = "Whether to automatically add comprehensive tags with VPN metadata"
  type        = bool
  default     = true
}

# ============================================================================
# ADVANCED CONFIGURATION
# ============================================================================

variable "public_ip_allocation_method" {
  description = "Public IP allocation method (Dynamic for Basic SKU, Static for Standard SKUs)"
  type        = string
  default     = null  # Auto-determined based on SKU
  
  validation {
    condition     = var.public_ip_allocation_method == null || contains(["Dynamic", "Static"], var.public_ip_allocation_method)
    error_message = "Public IP allocation method must be Dynamic or Static."
  }
}

variable "public_ip_sku" {
  description = "Public IP SKU (Basic for Basic VPN SKU, Standard for Standard VPN SKUs)"
  type        = string
  default     = null  # Auto-determined based on VPN Gateway SKU
  
  validation {
    condition     = var.public_ip_sku == null || contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "Public IP SKU must be Basic or Standard."
  }
}

variable "gateway_only_mode" {
  description = "Deploy only VPN Gateway without local network gateway or connection (useful for multi-site scenarios)"
  type        = bool
  default     = false
}

# ============================================================================
# VPN GATEWAY IP CONFIGURATION
# ============================================================================

variable "gateway_type" {
  description = "Type of the virtual network gateway (Vpn or ExpressRoute)"
  type        = string
  default     = "Vpn"
  
  validation {
    condition     = contains(["Vpn", "ExpressRoute"], var.gateway_type)
    error_message = "Gateway type must be Vpn or ExpressRoute."
  }
}

variable "ip_configuration_name" {
  description = "Name for the IP configuration of the VPN Gateway"
  type        = string
  default     = "vnetGatewayConfig"
  
  validation {
    condition     = length(var.ip_configuration_name) > 0 && length(var.ip_configuration_name) <= 80
    error_message = "IP configuration name must be between 1 and 80 characters."
  }
}

variable "private_ip_address_allocation" {
  description = "Private IP address allocation method for VPN Gateway (Dynamic or Static)"
  type        = string
  default     = "Dynamic"
  
  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "Private IP address allocation must be Dynamic or Static."
  }
}

variable "active_active" {
  description = "Enable active-active configuration for VPN Gateway (requires VpnGw2 or higher)"
  type        = bool
  default     = false
}

# ============================================================================
# VALIDATION CONFIGURATION
# ============================================================================

variable "validate_configuration_consistency" {
  description = "Internal validation variable - do not set manually"
  type        = bool
  default     = true
  
  validation {
    condition = !var.validate_configuration_consistency || (
      # If gateway_only_mode is false, both local_network_gateway and vpn_connection must be provided
      var.gateway_only_mode || (var.local_network_gateway != null && var.vpn_connection != null)
    )
    error_message = "When gateway_only_mode is false, both local_network_gateway and vpn_connection must be provided."
  }
  
  validation {
    condition = !var.validate_configuration_consistency || (
      # BGP is not supported on Basic SKU
      var.vpn_gateway_sku != "Basic" || !var.enable_bgp
    )
    error_message = "BGP is not supported on Basic VPN Gateway SKU."
  }
  
  validation {
    condition = !var.validate_configuration_consistency || (
      # Custom IPSec policy is not supported on Basic SKU
      var.vpn_gateway_sku != "Basic" || var.vpn_connection == null || var.vpn_connection.ipsec_policy == null
    )
    error_message = "Custom IPSec policy is not supported on Basic VPN Gateway SKU."
  }
  
  validation {
    condition = !var.validate_configuration_consistency || (
      # Generation2 is only supported on VpnGw4, VpnGw5, VpnGw4AZ, VpnGw5AZ
      var.vpn_gateway_generation != "Generation2" || contains(["VpnGw4", "VpnGw5", "VpnGw4AZ", "VpnGw5AZ"], var.vpn_gateway_sku)
    )
    error_message = "Generation2 is only supported on VpnGw4, VpnGw5, VpnGw4AZ, and VpnGw5AZ SKUs."
  }
}
