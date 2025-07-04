# Required Variables
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  
  validation {
    condition     = length(var.vm_name) > 0 && length(var.vm_name) <= 64
    error_message = "VM name must be between 1 and 64 characters."
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
  
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3",
      "Standard_E2s_v3", "Standard_E4s_v3", "Standard_E8s_v3",
      "Standard_F2s_v2", "Standard_F4s_v2", "Standard_F8s_v2"
    ], var.vm_size)
    error_message = "VM size must be a valid Azure VM size."
  }
}

variable "admin_username" {
  description = "Administrator username for the virtual machine"
  type        = string
  
  validation {
    condition     = length(var.admin_username) > 0 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 1 and 20 characters."
  }
}

variable "admin_password" {
  description = "Administrator password for the virtual machine"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 123
    error_message = "Admin password must be between 12 and 123 characters."
  }
}

# Optional Variables with Defaults
variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "Base name for the resource group (random suffix will be added)"
  type        = string
  default     = "rg-vm-poc"
}

variable "subnet_id" {
  description = "ID of the subnet where the VM will be deployed"
  type        = string
}

variable "enable_public_ip" {
  description = "Whether to create and assign a public IP to the VM"
  type        = bool
  default     = false
}

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

variable "nsg_rules" {
  description = "List of NSG rules to create when public IP is enabled"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
