# ============================================================================
# REQUIRED VARIABLES (Minimal Requirements)
# ============================================================================

variable "subnet_id" {
  description = "ID of the subnet where the SQL Server VM will be deployed"
  type        = string
  
  validation {
    condition     = var.subnet_id == null || length(var.subnet_id) > 0
    error_message = "Subnet ID cannot be empty when provided."
  }
}

variable "resource_group_name" {
  description = "Name for the resource group. If create_resource_group is false, this should be an existing RG"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "admin_username" {
  description = "Administrator username for the SQL Server VM"
  type        = string
  
  validation {
    condition     = length(var.admin_username) > 0 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 1 and 20 characters."
  }
}

# ============================================================================
# CORE SQL SERVER VM CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "vm_name" {
  description = "Name of the SQL Server virtual machine. If null, will auto-generate with timestamp"
  type        = string
  default     = null
  
  validation {
    condition     = var.vm_name == null || (length(var.vm_name) > 0 && length(var.vm_name) <= 64)
    error_message = "VM name must be between 1 and 64 characters when specified."
  }
}

variable "vm_size" {
  description = "Size of the SQL Server virtual machine (optimized for SQL Server workloads)"
  type        = string
  default     = "Standard_D4s_v3"
  
  validation {
    condition = contains([
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", "Standard_D16s_v3",
      "Standard_E4s_v3", "Standard_E8s_v3", "Standard_E16s_v3", "Standard_E32s_v3",
      "Standard_M8ms", "Standard_M16ms", "Standard_M32ms", "Standard_M64ms"
    ], var.vm_size)
    error_message = "VM size must be suitable for SQL Server workloads."
  }
}

variable "admin_password" {
  description = "Administrator password for the SQL Server VM (required)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 123
    error_message = "Admin password must be between 12 and 123 characters."
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

# ============================================================================
# SQL SERVER IMAGE CONFIGURATION (Smart Defaults)
# ============================================================================

variable "sql_image_defaults" {
  description = "Default SQL Server image configuration"
  type = object({
    publisher = string
    offer     = string
    sku       = string
  })
  default = {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "standard-gen2"
  }
}

variable "image_version" {
  description = "Version of the SQL Server image"
  type        = string
  default     = "latest"
}

variable "sql_edition" {
  description = "SQL Server edition (used for validation and tagging)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Express", "Standard", "Enterprise"], var.sql_edition)
    error_message = "SQL Server edition must be one of: Express, Standard, Enterprise."
  }
}

# ============================================================================
# STORAGE CONFIGURATION (SQL Server Optimized)
# ============================================================================

variable "os_disk_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Premium_LRS"
  
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "UltraSSD_LRS"
    ], var.os_disk_type)
    error_message = "OS disk type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, UltraSSD_LRS."
  }
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB. If null, uses the default size for the image"
  type        = number
  default     = null
  
  validation {
    condition     = var.os_disk_size_gb == null || (var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 4095)
    error_message = "OS disk size must be between 30 and 4095 GB when specified."
  }
}

variable "data_disk_config" {
  description = "Configuration for SQL Server data disk"
  type = object({
    size_gb              = number
    storage_account_type = string
    caching              = string
    lun                  = number
  })
  default = {
    size_gb              = 100
    storage_account_type = "Premium_LRS"
    caching              = "ReadOnly"
    lun                  = 0
  }
  
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "UltraSSD_LRS"
    ], var.data_disk_config.storage_account_type)
    error_message = "Data disk storage account type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, UltraSSD_LRS."
  }
  
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.data_disk_config.caching)
    error_message = "Data disk caching must be one of: None, ReadOnly, ReadWrite."
  }
  
  validation {
    condition     = var.data_disk_config.size_gb >= 10 && var.data_disk_config.size_gb <= 32767
    error_message = "Data disk size must be between 10 and 32767 GB."
  }
  
  validation {
    condition     = var.data_disk_config.lun >= 0 && var.data_disk_config.lun <= 63
    error_message = "Data disk LUN must be between 0 and 63."
  }
}

variable "log_disk_config" {
  description = "Configuration for SQL Server log disk"
  type = object({
    size_gb              = number
    storage_account_type = string
    caching              = string
    lun                  = number
  })
  default = {
    size_gb              = 50
    storage_account_type = "Premium_LRS"
    caching              = "None"
    lun                  = 1
  }
  
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "UltraSSD_LRS"
    ], var.log_disk_config.storage_account_type)
    error_message = "Log disk storage account type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, UltraSSD_LRS."
  }
  
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.log_disk_config.caching)
    error_message = "Log disk caching must be one of: None, ReadOnly, ReadWrite."
  }
  
  validation {
    condition     = var.log_disk_config.size_gb >= 10 && var.log_disk_config.size_gb <= 32767
    error_message = "Log disk size must be between 10 and 32767 GB."
  }
  
  validation {
    condition     = var.log_disk_config.lun >= 0 && var.log_disk_config.lun <= 63
    error_message = "Log disk LUN must be between 0 and 63."
  }
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "enable_public_ip" {
  description = "Whether to create and assign a public IP to the SQL Server VM"
  type        = bool
  default     = false
}

variable "public_ip_allocation_method" {
  description = "Allocation method for the public IP address"
  type        = string
  default     = "Static"
  
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "Public IP allocation method must be either 'Static' or 'Dynamic'."
  }
}

variable "public_ip_sku" {
  description = "SKU for the public IP address"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "Public IP SKU must be either 'Basic' or 'Standard'."
  }
}

variable "private_ip_allocation" {
  description = "Private IP address allocation method"
  type        = string
  default     = "Dynamic"
  
  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_allocation)
    error_message = "Private IP allocation must be either 'Dynamic' or 'Static'."
  }
}

variable "private_ip_address" {
  description = "Static private IP address (only used when private_ip_allocation is 'Static')"
  type        = string
  default     = null
}

# ============================================================================
# NETWORK SECURITY GROUP CONFIGURATION (Security-First)
# ============================================================================

variable "create_nsg" {
  description = "Whether to create a Network Security Group for the SQL Server VM"
  type        = bool
  default     = false
}

variable "sql_nsg_rules" {
  description = "List of NSG rules for SQL Server access (no automatic rules - explicit security)"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
  
  validation {
    condition = alltrue([
      for rule in var.sql_nsg_rules : contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "NSG rule direction must be either 'Inbound' or 'Outbound'."
  }
  
  validation {
    condition = alltrue([
      for rule in var.sql_nsg_rules : contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "NSG rule access must be either 'Allow' or 'Deny'."
  }
  
  validation {
    condition = alltrue([
      for rule in var.sql_nsg_rules : rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "NSG rule priority must be between 100 and 4096."
  }
}

# ============================================================================
# RESOURCE NAMING CONFIGURATION
# ============================================================================

variable "public_ip_name_prefix" {
  description = "Prefix for public IP resource name"
  type        = string
  default     = "pip"
}

variable "nsg_name_prefix" {
  description = "Prefix for Network Security Group resource name"
  type        = string
  default     = "nsg"
}

variable "nic_name_prefix" {
  description = "Prefix for Network Interface resource name"
  type        = string
  default     = "nic"
}

variable "data_disk_name_prefix" {
  description = "Prefix for data disk resource name"
  type        = string
  default     = "datadisk"
}

variable "log_disk_name_prefix" {
  description = "Prefix for log disk resource name"
  type        = string
  default     = "logdisk"
}

variable "os_disk_name" {
  description = "Name for the OS disk. If null, will auto-generate"
  type        = string
  default     = null
}

variable "nic_ip_configuration_name" {
  description = "Name for the NIC IP configuration"
  type        = string
  default     = "internal"
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
  description = "Whether to automatically add comprehensive tags with SQL Server specifications"
  type        = bool
  default     = true
}

# ============================================================================
# ADVANCED CONFIGURATION
# ============================================================================

variable "availability_set_id" {
  description = "ID of the availability set to place the SQL Server VM in"
  type        = string
  default     = null
}

variable "proximity_placement_group_id" {
  description = "ID of the proximity placement group to place the SQL Server VM in"
  type        = string
  default     = null
}

variable "zone" {
  description = "Availability zone for the SQL Server VM"
  type        = string
  default     = null
  
  validation {
    condition     = var.zone == null || contains(["1", "2", "3"], var.zone)
    error_message = "Zone must be one of: 1, 2, 3."
  }
}

variable "boot_diagnostics_enabled" {
  description = "Whether boot diagnostics are enabled"
  type        = bool
  default     = true
}

variable "identity_type" {
  description = "Type of managed identity for the SQL Server VM"
  type        = string
  default     = "SystemAssigned"
  
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned", "None"], var.identity_type)
    error_message = "Identity type must be one of: SystemAssigned, UserAssigned, SystemAssigned, UserAssigned, None."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = []
}

# ============================================================================
# SQL SERVER SPECIFIC CONFIGURATION
# ============================================================================

variable "sql_connectivity_type" {
  description = "SQL Server connectivity type for validation and documentation"
  type        = string
  default     = "PRIVATE"
  
  validation {
    condition     = contains(["LOCAL", "PRIVATE", "PUBLIC"], var.sql_connectivity_type)
    error_message = "SQL connectivity type must be one of: LOCAL, PRIVATE, PUBLIC."
  }
}

variable "sql_port" {
  description = "SQL Server port number"
  type        = number
  default     = 1433
  
  validation {
    condition     = var.sql_port >= 1024 && var.sql_port <= 65535
    error_message = "SQL Server port must be between 1024 and 65535."
  }
}

variable "sql_authentication_type" {
  description = "SQL Server authentication type for documentation"
  type        = string
  default     = "SQL"
  
  validation {
    condition     = contains(["SQL", "Windows"], var.sql_authentication_type)
    error_message = "SQL authentication type must be either 'SQL' or 'Windows'."
  }
}

# ============================================================================
# SQL SERVER IAAS AGENT EXTENSION CONFIGURATION
# ============================================================================

variable "sql_license_type" {
  description = "SQL Server license type (PAYG = Pay-as-you-go, AHUB = Azure Hybrid Benefit, DR = Disaster Recovery)"
  type        = string
  default     = "PAYG"
  
  validation {
    condition     = contains(["PAYG", "AHUB", "DR"], var.sql_license_type)
    error_message = "SQL license type must be one of: PAYG, AHUB, DR."
  }
}

variable "sql_workload_type" {
  description = "SQL Server workload type for storage optimization (GENERAL, OLTP, DW)"
  type        = string
  default     = "GENERAL"
  
  validation {
    condition     = contains(["GENERAL", "OLTP", "DW"], var.sql_workload_type)
    error_message = "SQL workload type must be one of: GENERAL, OLTP, DW."
  }
}

variable "enable_auto_backup" {
  description = "Whether to enable SQL Server automated backup"
  type        = bool
  default     = false
}

variable "auto_backup_retention_days" {
  description = "Retention period for automated backups in days (1-90)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.auto_backup_retention_days >= 1 && var.auto_backup_retention_days <= 90
    error_message = "Auto backup retention must be between 1 and 90 days."
  }
}

variable "backup_storage_endpoint" {
  description = "Storage blob endpoint for automated backups (required if enable_auto_backup is true)"
  type        = string
  default     = null
}

variable "backup_storage_access_key" {
  description = "Storage account access key for automated backups (required if enable_auto_backup is true)"
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_auto_patching" {
  description = "Whether to enable SQL Server automated patching"
  type        = bool
  default     = false
}

variable "auto_patching_day_of_week" {
  description = "Day of week for automated patching (Sunday, Monday, etc.)"
  type        = string
  default     = "Sunday"
  
  validation {
    condition = contains([
      "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ], var.auto_patching_day_of_week)
    error_message = "Auto patching day must be a valid day of the week."
  }
}

variable "auto_patching_start_hour" {
  description = "Start hour for automated patching maintenance window (0-23)"
  type        = number
  default     = 2
  
  validation {
    condition     = var.auto_patching_start_hour >= 0 && var.auto_patching_start_hour <= 23
    error_message = "Auto patching start hour must be between 0 and 23."
  }
}

variable "auto_patching_window_duration" {
  description = "Duration of automated patching maintenance window in minutes (30-180)"
  type        = number
  default     = 60
  
  validation {
    condition     = var.auto_patching_window_duration >= 30 && var.auto_patching_window_duration <= 180
    error_message = "Auto patching window duration must be between 30 and 180 minutes."
  }
}
