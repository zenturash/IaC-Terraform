# Global Configuration
variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "admin_username" {
  description = "Default administrator username for virtual machines"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Administrator password for virtual machines"
  type        = string
  sensitive   = true
  # No default for security - must be provided via terraform.tfvars or command line
}

# Multiple VMs Configuration
variable "virtual_machines" {
  description = "Map of virtual machines to create"
  type = map(object({
    vm_size             = string
    subnet_name         = string
    resource_group_name = string
    enable_public_ip    = optional(bool, true)
    os_disk_type        = optional(string, "Premium_LRS")
    admin_username      = optional(string)
    admin_password      = optional(string)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for vm in var.virtual_machines : contains([
        "Standard_B1s", "Standard_B2s", "Standard_B4ms",
        "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3",
        "Standard_E2s_v3", "Standard_E4s_v3", "Standard_E8s_v3",
        "Standard_F2s_v2", "Standard_F4s_v2", "Standard_F8s_v2"
      ], vm.vm_size)
    ])
    error_message = "All VM sizes must be valid Azure VM sizes."
  }
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/20"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet (deprecated - use subnets variable)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_names" {
  description = "List of subnet names to create. CIDRs will be automatically calculated"
  type        = list(string)
  default     = ["subnet-poc", "subnet-app", "subnet-mgmt"]
}

variable "create_gateway_subnet" {
  description = "Whether to create a GatewaySubnet (for VPN/ExpressRoute gateways)"
  type        = bool
  default     = false
}

# VPN Configuration
variable "enable_vpn" {
  description = "Whether to deploy VPN Gateway and connection"
  type        = bool
  default     = false
}

variable "vpn_configuration" {
  description = "VPN Gateway and connection configuration"
  type = object({
    vpn_gateway_name = string
    vpn_gateway_sku  = optional(string, "VpnGw1")
    vpn_type         = optional(string, "RouteBased")
    enable_bgp       = optional(bool, false)
    
    local_network_gateway = object({
      name            = string
      gateway_address = string           # Public IP of on-premises VPN device
      address_space   = list(string)     # On-premises network CIDRs
    })
    
    vpn_connection = object({
      name                = string
      shared_key          = string       # Pre-shared key for VPN connection
      connection_protocol = optional(string, "IKEv2")
    })
  })
  default = {
    vpn_gateway_name = "vpn-gateway"
    local_network_gateway = {
      name            = "local-gateway"
      gateway_address = "1.2.3.4"
      address_space   = ["192.168.0.0/16"]
    }
    vpn_connection = {
      name       = "vpn-connection"
      shared_key = "change-this-key"
    }
  }
  sensitive = true
}

variable "os_disk_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Premium_LRS"
}

# Azure Landing Zone (ALZ) Configuration
variable "architecture_mode" {
  description = "Architecture deployment mode: single-vnet (current) or hub-spoke (ALZ)"
  type        = string
  default     = "single-vnet"
  
  validation {
    condition     = contains(["single-vnet", "hub-spoke"], var.architecture_mode)
    error_message = "Architecture mode must be either 'single-vnet' or 'hub-spoke'."
  }
}

# Subscription Configuration
variable "subscriptions" {
  description = "Azure subscription configuration for multi-subscription deployments"
  type = object({
    hub_subscription_id   = optional(string)  # If null, uses default subscription
    spoke_subscription_id = optional(string)  # If null, uses default subscription
  })
  default = {
    hub_subscription_id   = null
    spoke_subscription_id = null
  }
}

variable "hub_vnet" {
  description = "Hub VNet configuration for connectivity (ALZ hub-spoke mode)"
  type = object({
    enabled             = bool
    name               = string
    resource_group_name = string
    cidr               = string
    location           = optional(string)
    subnets            = list(string)
  })
  default = {
    enabled             = false
    name               = "vnet-hub-connectivity"
    resource_group_name = "rg-hub-connectivity"
    cidr               = "10.1.0.0/20"
    location           = null  # Will use global location if not specified
    subnets            = ["GatewaySubnet", "AzureFirewallSubnet", "ManagementSubnet"]
  }
}

variable "spoke_vnets" {
  description = "Map of spoke VNets for workloads (ALZ hub-spoke mode)"
  type = map(object({
    enabled             = bool
    name               = string
    resource_group_name = string
    cidr               = string
    location           = optional(string)
    subnets            = list(string)
    peer_to_hub        = optional(bool, true)
  }))
  default = {}
}

variable "deploy_components" {
  description = "Control which components to deploy"
  type = object({
    vpn_gateway = bool
    vms         = bool
    peering     = bool
  })
  default = {
    vpn_gateway = false
    vms         = true
    peering     = false
  }
}

variable "vnet_peering" {
  description = "VNet peering configuration options"
  type = object({
    enabled                    = bool
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic    = optional(bool, true)
    allow_gateway_transit      = optional(bool, true)
    use_remote_gateways        = optional(bool, true)
  })
  default = {
    enabled                    = false
    allow_virtual_network_access = true
    allow_forwarded_traffic    = true
    allow_gateway_transit      = true
    use_remote_gateways        = true
  }
}
