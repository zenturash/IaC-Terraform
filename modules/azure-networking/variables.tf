# ============================================================================
# REQUIRED VARIABLES
# ============================================================================

variable "resource_group_name" {
  description = "Name of the resource group for networking resources"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  
  validation {
    condition     = length(var.vnet_name) > 0 && length(var.vnet_name) <= 64
    error_message = "VNet name must be between 1 and 64 characters."
  }
}

# ============================================================================
# CORE CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/20"
  
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "VNet CIDR must be a valid CIDR block."
  }
}

variable "subnet_names" {
  description = "List of subnet names to create. CIDRs will be automatically calculated"
  type        = list(string)
  default     = ["default"]
  
  validation {
    condition     = length(var.subnet_names) > 0
    error_message = "At least one subnet name must be provided."
  }
  
  validation {
    condition = alltrue([
      for name in var.subnet_names : length(name) > 0 && length(name) <= 80
    ])
    error_message = "Subnet names must be between 1 and 80 characters."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VNet prefix for subnets"
  type        = number
  default     = 4
  
  validation {
    condition     = var.subnet_newbits >= 1 && var.subnet_newbits <= 16
    error_message = "Subnet newbits must be between 1 and 16."
  }
}

# ============================================================================
# GATEWAY SUBNET CONFIGURATION
# ============================================================================

variable "create_gateway_subnet" {
  description = "Whether to create a GatewaySubnet (for VPN/ExpressRoute gateways)"
  type        = bool
  default     = false
}

variable "gateway_subnet_newbits" {
  description = "Number of additional bits for the GatewaySubnet (if created)"
  type        = number
  default     = 4
  
  validation {
    condition     = var.gateway_subnet_newbits >= 1 && var.gateway_subnet_newbits <= 16
    error_message = "Gateway subnet newbits must be between 1 and 16."
  }
}

# ============================================================================
# ADVANCED VNET CONFIGURATION
# ============================================================================

variable "dns_servers" {
  description = "List of DNS servers for the VNet. If empty, uses Azure default DNS"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for dns in var.dns_servers : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", dns))
    ])
    error_message = "DNS servers must be valid IP addresses."
  }
}

variable "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan to associate with the VNet"
  type        = string
  default     = null
}

variable "flow_timeout_in_minutes" {
  description = "Flow timeout in minutes for the VNet"
  type        = number
  default     = 4
  
  validation {
    condition     = var.flow_timeout_in_minutes >= 4 && var.flow_timeout_in_minutes <= 30
    error_message = "Flow timeout must be between 4 and 30 minutes."
  }
}

variable "bgp_community" {
  description = "BGP community attribute for the VNet"
  type        = string
  default     = null
}

# ============================================================================
# SUBNET ADVANCED CONFIGURATION
# ============================================================================

variable "subnet_service_endpoints" {
  description = "Map of subnet names to their service endpoints"
  type        = map(list(string))
  default     = {}
  
  validation {
    condition = alltrue([
      for endpoints in values(var.subnet_service_endpoints) : alltrue([
        for endpoint in endpoints : contains([
          "Microsoft.Storage", "Microsoft.Sql", "Microsoft.AzureCosmosDB",
          "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.EventHub",
          "Microsoft.AzureActiveDirectory", "Microsoft.CognitiveServices",
          "Microsoft.ContainerRegistry", "Microsoft.Web"
        ], endpoint)
      ])
    ])
    error_message = "Service endpoints must be valid Azure service endpoints."
  }
}

variable "subnet_service_endpoint_policies" {
  description = "Map of subnet names to their service endpoint policy IDs"
  type        = map(list(string))
  default     = {}
}

variable "subnet_delegations" {
  description = "Map of subnet names to their delegation configurations"
  type = map(object({
    name = string
    service_delegation = object({
      name    = string
      actions = list(string)
    })
  }))
  default = {}
}

variable "subnet_private_endpoint_network_policies_enabled" {
  description = "Map of subnet names to enable/disable private endpoint network policies"
  type        = map(bool)
  default     = {}
}

variable "subnet_private_link_service_network_policies_enabled" {
  description = "Map of subnet names to enable/disable private link service network policies"
  type        = map(bool)
  default     = {}
}

# ============================================================================
# NETWORK SECURITY GROUP CONFIGURATION
# ============================================================================

variable "create_subnet_nsgs" {
  description = "Map of subnet names to create NSGs for (true/false)"
  type        = map(bool)
  default     = {}
}

variable "subnet_nsg_rules" {
  description = "Map of subnet names to their NSG rules"
  type = map(list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  })))
  default = {}
  
  validation {
    condition = alltrue([
      for subnet_rules in values(var.subnet_nsg_rules) : alltrue([
        for rule in subnet_rules : contains(["Inbound", "Outbound"], rule.direction)
      ])
    ])
    error_message = "NSG rule direction must be either 'Inbound' or 'Outbound'."
  }
  
  validation {
    condition = alltrue([
      for subnet_rules in values(var.subnet_nsg_rules) : alltrue([
        for rule in subnet_rules : contains(["Allow", "Deny"], rule.access)
      ])
    ])
    error_message = "NSG rule access must be either 'Allow' or 'Deny'."
  }
  
  validation {
    condition = alltrue([
      for subnet_rules in values(var.subnet_nsg_rules) : alltrue([
        for rule in subnet_rules : rule.priority >= 100 && rule.priority <= 4096
      ])
    ])
    error_message = "NSG rule priority must be between 100 and 4096."
  }
}

variable "subnet_nsg_associations" {
  description = "Map of subnet names to their external NSG IDs for association (alternative to creating NSGs)"
  type        = map(string)
  default     = {}
}

variable "nsg_name_prefix" {
  description = "Prefix for NSG resource names"
  type        = string
  default     = "nsg"
}

variable "subnet_route_table_associations" {
  description = "Map of subnet names to their route table IDs for association"
  type        = map(string)
  default     = {}
}

# ============================================================================
# TAGGING CONFIGURATION
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_auto_tagging" {
  description = "Whether to automatically add comprehensive tags with network specifications"
  type        = bool
  default     = true
}

variable "subnet_tags" {
  description = "Map of subnet names to their specific tags (merged with global tags)"
  type        = map(map(string))
  default     = {}
}

# ============================================================================
# ADVANCED FEATURES
# ============================================================================

variable "enable_vm_protection" {
  description = "Enable VM protection for the VNet"
  type        = bool
  default     = false
}

variable "encryption" {
  description = "Enable encryption for the VNet"
  type        = string
  default     = "AllowUnencrypted"
  
  validation {
    condition     = contains(["AllowUnencrypted", "DropUnencrypted"], var.encryption)
    error_message = "Encryption must be either 'AllowUnencrypted' or 'DropUnencrypted'."
  }
}

# ============================================================================
# PEERING CONFIGURATION
# ============================================================================

variable "enable_peering_settings" {
  description = "Enable advanced peering settings for the VNet"
  type        = bool
  default     = false
}

variable "allow_virtual_network_access" {
  description = "Allow virtual network access for peering (when peering settings enabled)"
  type        = bool
  default     = true
}

variable "allow_forwarded_traffic" {
  description = "Allow forwarded traffic for peering (when peering settings enabled)"
  type        = bool
  default     = false
}

variable "allow_gateway_transit" {
  description = "Allow gateway transit for peering (when peering settings enabled)"
  type        = bool
  default     = false
}

variable "use_remote_gateways" {
  description = "Use remote gateways for peering (when peering settings enabled)"
  type        = bool
  default     = false
}
