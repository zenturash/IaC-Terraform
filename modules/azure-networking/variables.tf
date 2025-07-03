# Required Variables
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "subnet_names" {
  description = "List of subnet names to create. CIDRs will be automatically calculated"
  type        = list(string)
  default     = ["subnet-web", "subnet-app", "subnet-db"]
}

variable "create_gateway_subnet" {
  description = "Whether to create a GatewaySubnet (for VPN/ExpressRoute gateways)"
  type        = bool
  default     = false
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VNet prefix for subnets"
  type        = number
  default     = 4  # This creates /24 subnets from a /20 VNet (10.0.0.0/20 -> 10.0.0.0/24, 10.0.1.0/24, etc.)
}

# Optional Variables with Defaults
variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/20"
  
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "VNet CIDR must be a valid CIDR block."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
