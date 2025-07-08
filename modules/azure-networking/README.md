# Azure Networking Module

This module creates Azure Virtual Networks (VNets) and subnets with automatic CIDR calculation and flexible subnet configuration.

## Features

- **Automatic CIDR Calculation**: Subnets are automatically calculated from the VNet CIDR
- **Flexible Subnet Configuration**: Support for multiple subnets with custom names
- **Gateway Subnet Support**: Optional GatewaySubnet for VPN/ExpressRoute gateways
- **Resource Group Management**: Creates dedicated resource group for networking resources
- **Comprehensive Outputs**: Complete subnet and VNet information

## Usage

### Basic Usage

```hcl
module "networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-example"
  resource_group_name = "rg-networking"
  location            = "West Europe"
  vnet_cidr           = "10.0.0.0/20"
  
  subnet_names = ["subnet-web", "subnet-app", "subnet-db"]
  
  tags = {
    environment = "production"
    project     = "example"
  }
}
```

### With Gateway Subnet

```hcl
module "networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-hub"
  resource_group_name = "rg-hub-networking"
  location            = "West Europe"
  vnet_cidr           = "10.1.0.0/20"
  
  subnet_names = ["ManagementSubnet", "AzureFirewallSubnet"]
  create_gateway_subnet = true  # Creates GatewaySubnet automatically
  
  tags = {
    environment = "production"
    tier        = "networking-hub"
  }
}
```

### Custom Subnet Sizing

```hcl
module "networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-custom"
  resource_group_name = "rg-custom-networking"
  location            = "West Europe"
  vnet_cidr           = "10.2.0.0/16"
  
  subnet_names = ["subnet-large", "subnet-medium", "subnet-small"]
  subnet_newbits = 8  # Creates /24 subnets from /16 VNet
  
  tags = {
    environment = "development"
  }
}
```

## Subnet CIDR Calculation

The module automatically calculates subnet CIDRs using the `cidrsubnets` function:

### Example: VNet 10.0.0.0/20 with subnet_newbits = 4

- **VNet**: 10.0.0.0/20 (4096 addresses)
- **subnet-web**: 10.0.0.0/24 (256 addresses)
- **subnet-app**: 10.0.1.0/24 (256 addresses)
- **subnet-db**: 10.0.2.0/24 (256 addresses)
- **GatewaySubnet**: 10.0.15.0/24 (last available /24)

### Example: VNet 10.1.0.0/16 with subnet_newbits = 8

- **VNet**: 10.1.0.0/16 (65536 addresses)
- **subnet-large**: 10.1.0.0/24 (256 addresses)
- **subnet-medium**: 10.1.1.0/24 (256 addresses)
- **subnet-small**: 10.1.2.0/24 (256 addresses)
- **GatewaySubnet**: 10.1.255.0/24 (last available /24)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | n/a | yes |
| vnet_cidr | CIDR block for the virtual network | `string` | `"10.0.0.0/20"` | no |
| subnet_names | List of subnet names to create | `list(string)` | `["subnet-web", "subnet-app", "subnet-db"]` | no |
| create_gateway_subnet | Whether to create a GatewaySubnet | `bool` | `false` | no |
| subnet_newbits | Number of additional bits to extend the VNet prefix for subnets | `number` | `4` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| networking_resource_group_name | Name of the networking resource group |
| networking_resource_group_id | ID of the networking resource group |
| vnet_name | Name of the virtual network |
| vnet_id | ID of the virtual network |
| vnet_address_space | Address space of the virtual network |
| subnet_ids | Map of subnet names to their IDs |
| subnet_names | List of subnet names |
| subnets | Complete subnet information |
| subnet_id | ID of the first subnet (for backward compatibility) |
| subnet_name | Name of the first subnet (for backward compatibility) |

## Examples

### Hub VNet for ALZ

```hcl
module "hub_networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-hub-connectivity"
  resource_group_name = "rg-hub-connectivity"
  location            = "West Europe"
  vnet_cidr           = "10.1.0.0/20"
  
  subnet_names = ["ManagementSubnet", "AzureFirewallSubnet"]
  create_gateway_subnet = true
  
  tags = {
    environment = "production"
    tier        = "networking-hub"
    role        = "connectivity"
  }
}
```

### Spoke VNet for Workloads

```hcl
module "spoke_networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-spoke-production"
  resource_group_name = "rg-spoke-production"
  location            = "West Europe"
  vnet_cidr           = "10.2.0.0/20"
  
  subnet_names = ["subnet-web", "subnet-app", "subnet-db"]
  create_gateway_subnet = false  # Spokes don't need gateway subnets
  
  tags = {
    environment = "production"
    tier        = "networking-spoke"
    role        = "workload"
  }
}
```

### Development Environment

```hcl
module "dev_networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-development"
  resource_group_name = "rg-dev-networking"
  location            = "West Europe"
  vnet_cidr           = "10.10.0.0/20"
  
  subnet_names = ["subnet-dev", "subnet-test"]
  
  tags = {
    environment = "development"
    auto_shutdown = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Resources

- `azurerm_resource_group.networking`
- `azurerm_virtual_network.main`
- `azurerm_subnet.subnets` (multiple)

## Notes

- The GatewaySubnet is always created as the last available subnet in the VNet address space
- Subnet names must be unique within the VNet
- The module validates that the VNet CIDR is a valid CIDR block
- All subnets are created with the same size based on `subnet_newbits`
- For custom subnet sizes, consider using multiple module calls or the azurerm_subnet resource directly
