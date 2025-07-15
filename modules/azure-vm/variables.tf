# ============================================================================
# REQUIRED VARIABLES (Minimal Requirements)
# ============================================================================

variable "subnet_id" {
  description = "ID of the subnet where the VM will be deployed"
  type        = string
  
  validation {
    condition     = length(var.subnet_id) > 0
    error_message = "Subnet ID cannot be empty."
  }
}

# ============================================================================
# CORE VM CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "vm_name" {
  description = "Name of the virtual machine. If null, will auto-generate with random suffix"
  type        = string
  default     = null
  
  validation {
    condition     = var.vm_name == null || (length(var.vm_name) > 0 && length(var.vm_name) <= 64)
    error_message = "VM name must be between 1 and 64 characters when specified."
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
  
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_B4ms", "Standard_B8ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", "Standard_D16s_v3",
      "Standard_E2s_v3", "Standard_E4s_v3", "Standard_E8s_v3", "Standard_E16s_v3",
      "Standard_F2s_v2", "Standard_F4s_v2", "Standard_F8s_v2", "Standard_F16s_v2",
      "Standard_DS1_v2", "Standard_DS2_v2", "Standard_DS3_v2", "Standard_DS4_v2"
    ], var.vm_size)
    error_message = "VM size must be a valid Azure VM size."
  }
}

variable "admin_username" {
  description = "Administrator username for the virtual machine"
  type        = string
  default     = "azureuser"
  
  validation {
    condition     = length(var.admin_username) > 0 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 1 and 20 characters."
  }
}

variable "admin_password" {
  description = "Administrator password for the virtual machine. If null, will auto-generate secure password"
  type        = string
  default     = null
  sensitive   = true
  
  validation {
    condition     = var.admin_password == null || (length(var.admin_password) >= 12 && length(var.admin_password) <= 123)
    error_message = "Admin password must be between 12 and 123 characters when specified."
  }
}

# ============================================================================
# LOCATION AND RESOURCE GROUP CONFIGURATION
# ============================================================================

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "Name for the resource group. If create_resource_group is false, this should be an existing RG"
  type        = string
  default     = "rg-vm-poc"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "enable_public_ip" {
  description = "Whether to create and assign a public IP to the VM"
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
# NETWORK SECURITY GROUP CONFIGURATION
# ============================================================================

variable "create_nsg" {
  description = "Whether to create a Network Security Group for the VM"
  type        = bool
  default     = false
}


variable "nsg_rules" {
  description = "List of additional NSG rules to create"
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
      for rule in var.nsg_rules : contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "NSG rule direction must be either 'Inbound' or 'Outbound'."
  }
  
  validation {
    condition = alltrue([
      for rule in var.nsg_rules : contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "NSG rule access must be either 'Allow' or 'Deny'."
  }
  
  validation {
    condition = alltrue([
      for rule in var.nsg_rules : rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "NSG rule priority must be between 100 and 4096."
  }
}

# ============================================================================
# STORAGE CONFIGURATION
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

variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
  default     = "ReadWrite"
  
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "OS disk caching must be one of: None, ReadOnly, ReadWrite."
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

# ============================================================================
# VM IMAGE CONFIGURATION
# ============================================================================

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "2025-datacenter-azure-edition"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

# ============================================================================
# VM CONFIGURATION OPTIONS
# ============================================================================

variable "patch_mode" {
  description = "Patch mode for the virtual machine"
  type        = string
  default     = "AutomaticByPlatform"
  
  validation {
    condition     = contains(["Manual", "AutomaticByOS", "AutomaticByPlatform"], var.patch_mode)
    error_message = "Patch mode must be one of: Manual, AutomaticByOS, AutomaticByPlatform."
  }
}

variable "hotpatching_enabled" {
  description = "Whether hotpatching is enabled for the VM"
  type        = bool
  default     = false
}

variable "timezone" {
  description = "Timezone for the virtual machine"
  type        = string
  default     = "UTC"
}

variable "enable_automatic_updates" {
  description = "Whether automatic updates are enabled"
  type        = bool
  default     = true
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

variable "nic_ip_configuration_name" {
  description = "Name for the NIC IP configuration"
  type        = string
  default     = "internal"
}

variable "os_disk_name" {
  description = "Name for the OS disk. If null, will auto-generate"
  type        = string
  default     = null
}

variable "use_random_suffix" {
  description = "Whether to add random suffix to resource names for uniqueness"
  type        = bool
  default     = true
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
  description = "Whether to automatically add comprehensive tags with VM specifications"
  type        = bool
  default     = true
}

# ============================================================================
# ADVANCED CONFIGURATION
# ============================================================================

variable "availability_set_id" {
  description = "ID of the availability set to place the VM in"
  type        = string
  default     = null
}

variable "proximity_placement_group_id" {
  description = "ID of the proximity placement group to place the VM in"
  type        = string
  default     = null
}

variable "zone" {
  description = "Availability zone for the VM"
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
  description = "Type of managed identity for the VM"
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
