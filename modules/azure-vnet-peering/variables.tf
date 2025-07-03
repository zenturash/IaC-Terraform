# Required Variables
variable "hub_vnet_id" {
  description = "ID of the hub virtual network"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub virtual network"
  type        = string
}

variable "peering_connections" {
  description = "Map of spoke VNets to peer with the hub"
  type = map(object({
    spoke_vnet_id               = string
    spoke_vnet_name             = string
    spoke_resource_group_name   = string
  }))
  default = {}
}

variable "peering_config" {
  description = "VNet peering configuration options"
  type = object({
    allow_virtual_network_access = bool
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    use_remote_gateways         = bool
  })
  default = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
    allow_gateway_transit        = true
    use_remote_gateways         = true
  }
}

variable "tags" {
  description = "Tags to apply to peering resources"
  type        = map(string)
  default     = {}
}
