# Resource Group for Networking
resource "azurerm_resource_group" "networking" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = var.tags
}

# Calculate subnet CIDRs automatically using cidrsubnets function
locals {
  # Generate regular subnet CIDRs sequentially from the beginning
  regular_subnet_cidrs = cidrsubnets(var.vnet_cidr, [for i in range(length(var.subnet_names)) : var.subnet_newbits]...)
  
  # Regular subnets get the first CIDRs
  regular_subnets = {
    for i, name in var.subnet_names : name => {
      cidr = local.regular_subnet_cidrs[i]
    }
  }
  
  # Gateway subnet gets the LAST possible /24 in the entire VNet address space
  # For 10.0.0.0/20, this would be 10.0.15.0/24
  gateway_subnet = var.create_gateway_subnet ? {
    "GatewaySubnet" = {
      cidr = cidrsubnet(var.vnet_cidr, var.subnet_newbits, pow(2, var.subnet_newbits) - 1)
    }
  } : {}
  
  # Combine all subnets
  subnets = merge(local.regular_subnets, local.gateway_subnet)
}

# Multiple Subnets with automatically calculated CIDRs
resource "azurerm_subnet" "subnets" {
  for_each = local.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr]
}
