# ============================================================================
# REQUIRED VARIABLES (Minimal Requirements)
# ============================================================================

variable "hub_vnet_id" {
  description = "ID of the hub virtual network"
  type        = string
  
  validation {
    condition     = length(var.hub_vnet_id) > 0
    error_message = "Hub VNet ID cannot be empty."
  }
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
  
  validation {
    condition     = length(var.hub_vnet_name) > 0 && length(var.hub_vnet_name) <= 64
    error_message = "Hub VNet name must be between 1 and 64 characters."
  }
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub virtual network"
  type        = string
  
  validation {
    condition     = length(var.hub_resource_group_name) > 0 && length(var.hub_resource_group_name) <= 90
    error_message = "Hub resource group name must be between 1 and 90 characters."
  }
}

# ============================================================================
# PEERING CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "peering_connections" {
  description = "Map of spoke VNets to peer with the hub"
  type = map(object({
    spoke_vnet_id               = string
    spoke_vnet_name             = string
    spoke_resource_group_name   = string
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for k, v in var.peering_connections : length(v.spoke_vnet_id) > 0
    ])
    error_message = "All spoke VNet IDs must be non-empty."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.peering_connections : length(v.spoke_vnet_name) > 0 && length(v.spoke_vnet_name) <= 64
    ])
    error_message = "All spoke VNet names must be between 1 and 64 characters."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.peering_connections : length(v.spoke_resource_group_name) > 0 && length(v.spoke_resource_group_name) <= 90
    ])
    error_message = "All spoke resource group names must be between 1 and 90 characters."
  }
}

variable "peering_config" {
  description = "VNet peering configuration options with ALZ-optimized defaults"
  type = object({
    allow_virtual_network_access = bool
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    use_remote_gateways         = bool
  })
  default = {
    allow_virtual_network_access = true   # Allow VMs to communicate between hub and spokes
    allow_forwarded_traffic      = true   # Enable hub routing (required for spoke-to-spoke via hub)
    allow_gateway_transit        = true   # Hub provides gateway services (VPN/ExpressRoute)
    use_remote_gateways         = true   # Spokes use hub gateway for external connectivity
  }
  
  validation {
    condition = contains([true, false], var.peering_config.allow_virtual_network_access)
    error_message = "allow_virtual_network_access must be true or false."
  }
  
  validation {
    condition = contains([true, false], var.peering_config.allow_forwarded_traffic)
    error_message = "allow_forwarded_traffic must be true or false."
  }
  
  validation {
    condition = contains([true, false], var.peering_config.allow_gateway_transit)
    error_message = "allow_gateway_transit must be true or false."
  }
  
  validation {
    condition = contains([true, false], var.peering_config.use_remote_gateways)
    error_message = "use_remote_gateways must be true or false."
  }
}

# ============================================================================
# NAMING CONFIGURATION
# ============================================================================

variable "peering_name_prefix" {
  description = "Prefix for peering connection names"
  type        = string
  default     = "peer"
  
  validation {
    condition     = length(var.peering_name_prefix) > 0 && length(var.peering_name_prefix) <= 20
    error_message = "Peering name prefix must be between 1 and 20 characters."
  }
}


# ============================================================================
# TAGGING CONFIGURATION
# ============================================================================

variable "tags" {
  description = "Tags to apply to all peering resources"
  type        = map(string)
  default     = {}
}

variable "enable_auto_tagging" {
  description = "Whether to automatically add comprehensive tags with peering metadata"
  type        = bool
  default     = true
}

# ============================================================================
# VALIDATION CONFIGURATION
# ============================================================================

variable "validate_gateway_consistency" {
  description = "Internal validation variable - do not set manually"
  type        = bool
  default     = true
  
  validation {
    condition = !var.validate_gateway_consistency || (
      # Logical consistency: if hub allows gateway transit, 
      # it typically shouldn't use remote gateways itself
      var.peering_config.allow_gateway_transit ? 
        !var.peering_config.use_remote_gateways : true
    )
    error_message = "Hub VNet should provide gateway services (allow_gateway_transit=true) but not use remote gateways (use_remote_gateways=false) in typical hub-spoke architecture."
  }
}
