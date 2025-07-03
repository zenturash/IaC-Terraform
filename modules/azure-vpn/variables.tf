# Required Variables
variable "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for VPN resources"
  type        = string
}

variable "location" {
  description = "Azure region where VPN resources will be created"
  type        = string
}

variable "gateway_subnet_id" {
  description = "ID of the GatewaySubnet where VPN Gateway will be deployed"
  type        = string
}

# Local Network Gateway Configuration
variable "local_network_gateway" {
  description = "Configuration for the local network gateway (on-premises)"
  type = object({
    name               = string
    gateway_address    = string           # Public IP of on-premises VPN device
    address_space      = list(string)     # On-premises network CIDRs
  })
}

# VPN Connection Configuration
variable "vpn_connection" {
  description = "Configuration for the VPN connection"
  type = object({
    name                = string
    shared_key          = string          # Pre-shared key for VPN connection
    connection_protocol = optional(string, "IKEv2")
    ipsec_policy = optional(object({
      dh_group         = optional(string, "DHGroup14")
      ike_encryption   = optional(string, "AES256")
      ike_integrity    = optional(string, "SHA256")
      ipsec_encryption = optional(string, "AES256")
      ipsec_integrity  = optional(string, "SHA256")
      pfs_group        = optional(string, "PFS14")
      sa_lifetime      = optional(number, 3600)
    }), {})
  })
  sensitive = true
}

# Optional Variables with Defaults
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
}

variable "tags" {
  description = "Tags to apply to VPN resources"
  type        = map(string)
  default     = {}
}
