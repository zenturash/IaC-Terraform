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

variable "os_disk_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Premium_LRS"
}
