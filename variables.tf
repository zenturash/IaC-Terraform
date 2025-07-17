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

# Global Tagging Configuration
variable "global_tags" {
  description = "Global tags to apply to all resources"
  type        = map(string)
  default = {
    environment     = "POC"
    project         = "Azure ALZ POC"
    creation_method = "OpenTofu"
  }
}

# Multiple VMs Configuration
variable "virtual_machines" {
  description = "Map of virtual machines to create"
  type = map(object({
    vm_size             = optional(string, "Standard_B2s")  # Made optional with default to match module
    subnet_name         = string
    resource_group_name = string
    enable_public_ip    = optional(bool, true)
    os_disk_type        = optional(string, "Premium_LRS")
    admin_username      = optional(string)
    admin_password      = optional(string)
    spoke_name          = optional(string)  # Which spoke to deploy to (hub-spoke mode only)
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
      ], vm.vm_size != null ? vm.vm_size : "Standard_B2s")
    ])
    error_message = "All VM sizes must be valid Azure VM sizes."
  }
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
    hub   = optional(string)  # Hub/Connectivity subscription ID. If null, uses default subscription
    spoke = optional(map(string), {})  # Map of spoke names to subscription IDs: { "prod" = "sub-id", "dev" = "sub-id" }
  })
  default = {
    hub   = null
    spoke = {}
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
    spoke_name          = optional(string)  # Which subscription from subscriptions.spoke to use (defaults to VNet key name)
  }))
  default = {}
}

variable "deploy_components" {
  description = "Control which components to deploy"
  type = object({
    vpn_gateway     = bool
    vms             = bool
    peering         = bool
    backup_services = bool
  })
  default = {
    vpn_gateway     = false
    vms             = true
    peering         = false
    backup_services = false
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

# SQL Server VMs Configuration
variable "sql_server_vms" {
  description = "Map of SQL Server VMs to create using the azure-sql-vm module"
  type = map(object({
    # Required variables
    subnet_name         = string
    resource_group_name = string
    admin_username      = string
    admin_password      = string
    
    # Optional SQL Server configuration
    vm_size             = optional(string, "Standard_D4s_v3")
    sql_edition         = optional(string, "Standard")
    spoke_name          = optional(string)  # Which spoke to deploy to (hub-spoke mode only)
    
    # Optional storage configuration
    data_disk_config = optional(object({
      size_gb              = number
      storage_account_type = string
      caching              = string
      lun                  = number
    }), {
      size_gb              = 100
      storage_account_type = "Premium_LRS"
      caching              = "ReadOnly"
      lun                  = 0
    })
    
    log_disk_config = optional(object({
      size_gb              = number
      storage_account_type = string
      caching              = string
      lun                  = number
    }), {
      size_gb              = 50
      storage_account_type = "Premium_LRS"
      caching              = "None"
      lun                  = 1
    })
    
    # Optional network configuration
    enable_public_ip = optional(bool, false)
    create_nsg       = optional(bool, false)
    sql_nsg_rules = optional(list(object({
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
    
    # Optional tags
    tags = optional(map(string), {})
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for vm in var.sql_server_vms : contains([
        "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", "Standard_D16s_v3",
        "Standard_E4s_v3", "Standard_E8s_v3", "Standard_E16s_v3", "Standard_E32s_v3",
        "Standard_M8ms", "Standard_M16ms", "Standard_M32ms", "Standard_M64ms"
      ], vm.vm_size != null ? vm.vm_size : "Standard_D4s_v3")
    ])
    error_message = "All SQL Server VM sizes must be suitable for SQL Server workloads."
  }
  
  validation {
    condition = alltrue([
      for vm in var.sql_server_vms : contains(["Express", "Standard", "Enterprise"], vm.sql_edition != null ? vm.sql_edition : "Standard")
    ])
    error_message = "SQL Server edition must be one of: Express, Standard, Enterprise."
  }
}

# Backup Services Configuration
variable "backup_configuration" {
  description = "Azure Backup Services configuration"
  type = object({
    # Required configuration
    resource_group_name = string
    
    # Backup policies configuration (security-first: opt-in)
    policies = object({
      vm_daily       = optional(bool, false)
      vm_enhanced    = optional(bool, false)
      files_daily    = optional(bool, false)
      blob_daily     = optional(bool, false)
      sql_hourly_log = optional(bool, false)
    })
    
    # VM backup configuration (ARM template defaults)
    vm_backup_time           = optional(string, "01:00")
    vm_backup_retention_days = optional(number, 30)
    vm_backup_timezone       = optional(string, "Romance Standard Time")
    
    # Files backup configuration (ARM template defaults)
    files_backup_time           = optional(string, "01:00")
    files_backup_retention_days = optional(number, 30)
    
    # Blob backup configuration (ARM template defaults)
    blob_backup_retention_days = optional(number, 30)
    
    # SQL backup configuration (ARM template defaults)
    sql_full_backup_time           = optional(string, "18:00")
    sql_full_backup_retention_days = optional(number, 30)
    sql_log_backup_frequency_minutes = optional(number, 60)
    sql_log_backup_retention_days  = optional(number, 30)
    
    # Alert configuration (ARM template defaults)
    enable_backup_alerts = optional(bool, true)
    alert_send_to_owners = optional(string, "DoNotSend")
    alert_custom_email_addresses = optional(list(string), [])
  })
  default = {
    resource_group_name = "rg-backup-services"
    policies = {
      vm_daily       = false
      vm_enhanced    = false
      files_daily    = false
      blob_daily     = false
      sql_hourly_log = false
    }
    vm_backup_time           = "01:00"
    vm_backup_retention_days = 30
    vm_backup_timezone       = "Romance Standard Time"
    files_backup_time           = "01:00"
    files_backup_retention_days = 30
    blob_backup_retention_days = 30
    sql_full_backup_time           = "18:00"
    sql_full_backup_retention_days = 30
    sql_log_backup_frequency_minutes = 60
    sql_log_backup_retention_days  = 30
    enable_backup_alerts = true
    alert_send_to_owners = "DoNotSend"
    alert_custom_email_addresses = []
  }
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_configuration.vm_backup_time))
    error_message = "VM backup time must be in HH:MM format (24-hour)."
  }
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_configuration.files_backup_time))
    error_message = "Files backup time must be in HH:MM format (24-hour)."
  }
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_configuration.sql_full_backup_time))
    error_message = "SQL full backup time must be in HH:MM format (24-hour)."
  }
  
  validation {
    condition     = contains(["Send", "DoNotSend"], var.backup_configuration.alert_send_to_owners)
    error_message = "Alert send to owners must be either 'Send' or 'DoNotSend'."
  }
  
  validation {
    condition = alltrue([
      for email in var.backup_configuration.alert_custom_email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}
