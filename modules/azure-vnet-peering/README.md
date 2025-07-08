# Azure VNet Peering Module

This module creates bidirectional VNet peering connections between a hub VNet and multiple spoke VNets, supporting both same-subscription and cross-subscription peering scenarios.

## Features

- **Bidirectional Peering**: Automatic creation of both hub-to-spoke and spoke-to-hub peering
- **Multi-Spoke Support**: Connect multiple spoke VNets to a single hub VNet
- **Cross-Subscription**: Support for peering across different Azure subscriptions
- **Gateway Transit**: Configure gateway transit for centralized connectivity
- **Flexible Configuration**: Customizable peering settings per connection
- **Provider Aliases**: Support for different provider configurations

## Usage

### Basic Hub-Spoke Peering

```hcl
module "vnet_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Hub VNet information
  hub_vnet_id               = "/subscriptions/.../virtualNetworks/vnet-hub"
  hub_vnet_name             = "vnet-hub"
  hub_resource_group_name   = "rg-hub"

  # Spoke VNets to peer
  peering_connections = {
    "production" = {
      spoke_vnet_id               = "/subscriptions/.../virtualNetworks/vnet-spoke-prod"
      spoke_vnet_name             = "vnet-spoke-prod"
      spoke_resource_group_name   = "rg-spoke-prod"
    }
    "development" = {
      spoke_vnet_id               = "/subscriptions/.../virtualNetworks/vnet-spoke-dev"
      spoke_vnet_name             = "vnet-spoke-dev"
      spoke_resource_group_name   = "rg-spoke-dev"
    }
  }

  tags = {
    environment = "production"
    tier        = "networking"
  }
}
```

### Advanced Peering with Gateway Transit

```hcl
module "vnet_peering_gateway" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Hub VNet information
  hub_vnet_id               = module.hub_networking.vnet_id
  hub_vnet_name             = module.hub_networking.vnet_name
  hub_resource_group_name   = module.hub_networking.networking_resource_group_name

  # Multiple spoke VNets
  peering_connections = {
    "workload-1" = {
      spoke_vnet_id               = module.spoke_networking["workload-1"].vnet_id
      spoke_vnet_name             = module.spoke_networking["workload-1"].vnet_name
      spoke_resource_group_name   = module.spoke_networking["workload-1"].networking_resource_group_name
    }
    "workload-2" = {
      spoke_vnet_id               = module.spoke_networking["workload-2"].vnet_id
      spoke_vnet_name             = module.spoke_networking["workload-2"].vnet_name
      spoke_resource_group_name   = module.spoke_networking["workload-2"].networking_resource_group_name
    }
  }

  # Peering configuration with gateway transit
  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
    allow_gateway_transit        = true   # Hub provides gateway
    use_remote_gateways         = true   # Spokes use hub gateway
  }

  tags = {
    environment = "production"
    tier        = "networking-peering"
    gateway_transit = "enabled"
  }
}
```

### Cross-Subscription Peering

```hcl
# Configure providers for different subscriptions
provider "azurerm" {
  alias           = "hub"
  subscription_id = "hub-subscription-id"
  features {}
}

provider "azurerm" {
  alias           = "spoke"
  subscription_id = "spoke-subscription-id"
  features {}
}

module "cross_subscription_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Hub VNet in connectivity subscription
  hub_vnet_id               = "/subscriptions/hub-sub-id/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
  hub_vnet_name             = "vnet-hub"
  hub_resource_group_name   = "rg-hub"

  # Spoke VNets in workload subscription
  peering_connections = {
    "cross-sub-workload" = {
      spoke_vnet_id               = "/subscriptions/spoke-sub-id/resourceGroups/rg-workload/providers/Microsoft.Network/virtualNetworks/vnet-workload"
      spoke_vnet_name             = "vnet-workload"
      spoke_resource_group_name   = "rg-workload"
    }
  }

  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
    allow_gateway_transit        = true
    use_remote_gateways         = true
  }

  tags = {
    environment = "production"
    tier        = "cross-subscription-peering"
  }
}
```

## Peering Configuration Options

### Standard Configuration
```hcl
peering_config = {
  allow_virtual_network_access = true   # Allow VMs to communicate
  allow_forwarded_traffic      = true   # Allow traffic forwarding
  allow_gateway_transit        = true   # Hub can provide gateway services
  use_remote_gateways         = true   # Spokes use hub gateway
}
```

### Isolated Spokes (No Inter-Spoke Communication)
```hcl
peering_config = {
  allow_virtual_network_access = true   # Allow hub-spoke communication
  allow_forwarded_traffic      = false  # Prevent inter-spoke traffic
  allow_gateway_transit        = true   # Hub provides gateway
  use_remote_gateways         = true   # Spokes use hub gateway
}
```

### No Gateway Transit
```hcl
peering_config = {
  allow_virtual_network_access = true   # Allow VMs to communicate
  allow_forwarded_traffic      = true   # Allow traffic forwarding
  allow_gateway_transit        = false  # No gateway services
  use_remote_gateways         = false  # No remote gateway usage
}
```

## Peering Settings Explained

### allow_virtual_network_access
- **true**: VMs in peered VNets can communicate directly
- **false**: VMs cannot communicate (rarely used)

### allow_forwarded_traffic
- **true**: Traffic can be forwarded through the peered VNet (enables hub routing)
- **false**: Only direct traffic allowed (isolates spokes)

### allow_gateway_transit
- **true**: Hub VNet can provide gateway services (VPN, ExpressRoute) to spokes
- **false**: Hub cannot provide gateway services

### use_remote_gateways
- **true**: Spoke VNets use the hub's gateway for external connectivity
- **false**: Spoke VNets don't use remote gateways

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| hub_vnet_id | ID of the hub virtual network | `string` | n/a | yes |
| hub_vnet_name | Name of the hub virtual network | `string` | n/a | yes |
| hub_resource_group_name | Resource group name of the hub virtual network | `string` | n/a | yes |
| peering_connections | Map of spoke VNets to peer with the hub | `map(object)` | `{}` | no |
| peering_config | VNet peering configuration options | `object` | See defaults | no |
| tags | Tags to apply to peering resources | `map(string)` | `{}` | no |

### peering_connections Object Structure
```hcl
peering_connections = {
  "spoke-name" = {
    spoke_vnet_id               = string  # Full resource ID of spoke VNet
    spoke_vnet_name             = string  # Name of spoke VNet
    spoke_resource_group_name   = string  # Resource group of spoke VNet
  }
}
```

### peering_config Object Structure
```hcl
peering_config = {
  allow_virtual_network_access = bool    # Default: true
  allow_forwarded_traffic      = bool    # Default: true
  allow_gateway_transit        = bool    # Default: true
  use_remote_gateways         = bool    # Default: true
}
```

## Outputs

| Name | Description |
|------|-------------|
| hub_to_spoke_peering_ids | Map of hub to spoke peering IDs |
| hub_to_spoke_peering_names | Map of hub to spoke peering names |
| spoke_to_hub_peering_ids | Map of spoke to hub peering IDs |
| spoke_to_hub_peering_names | Map of spoke to hub peering names |
| peering_status | Status of all VNet peerings |
| peering_summary | Summary of all peering connections |

## Examples

### ALZ Hub-Spoke with Multiple Workloads

```hcl
module "alz_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Hub VNet (connectivity subscription)
  hub_vnet_id               = module.hub_networking.vnet_id
  hub_vnet_name             = "vnet-hub-connectivity"
  hub_resource_group_name   = "rg-hub-connectivity"

  # Multiple spoke VNets (workload subscriptions)
  peering_connections = {
    "production" = {
      spoke_vnet_id               = module.spoke_networking["production"].vnet_id
      spoke_vnet_name             = "vnet-spoke-production"
      spoke_resource_group_name   = "rg-spoke-production"
    }
    "development" = {
      spoke_vnet_id               = module.spoke_networking["development"].vnet_id
      spoke_vnet_name             = "vnet-spoke-development"
      spoke_resource_group_name   = "rg-spoke-development"
    }
    "dmz" = {
      spoke_vnet_id               = module.spoke_networking["dmz"].vnet_id
      spoke_vnet_name             = "vnet-spoke-dmz"
      spoke_resource_group_name   = "rg-spoke-dmz"
    }
  }

  # Standard ALZ peering configuration
  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
    allow_gateway_transit        = true
    use_remote_gateways         = true
  }

  tags = {
    environment = "production"
    tier        = "networking-peering"
    architecture = "alz-hub-spoke"
  }
}
```

### Development Environment Peering

```hcl
module "dev_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm
    azurerm.spoke = azurerm
  }

  # Development hub
  hub_vnet_id               = module.dev_hub_networking.vnet_id
  hub_vnet_name             = "vnet-dev-hub"
  hub_resource_group_name   = "rg-dev-hub"

  # Development spokes
  peering_connections = {
    "dev-app" = {
      spoke_vnet_id               = module.dev_app_networking.vnet_id
      spoke_vnet_name             = "vnet-dev-app"
      spoke_resource_group_name   = "rg-dev-app"
    }
    "dev-test" = {
      spoke_vnet_id               = module.dev_test_networking.vnet_id
      spoke_vnet_name             = "vnet-dev-test"
      spoke_resource_group_name   = "rg-dev-test"
    }
  }

  # No gateway transit for development
  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
    allow_gateway_transit        = false
    use_remote_gateways         = false
  }

  tags = {
    environment = "development"
    tier        = "networking-peering"
    auto_shutdown = "true"
  }
}
```

### Secure Isolated Spokes

```hcl
module "secure_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Security hub
  hub_vnet_id               = module.security_hub.vnet_id
  hub_vnet_name             = "vnet-security-hub"
  hub_resource_group_name   = "rg-security-hub"

  # Isolated workload spokes
  peering_connections = {
    "secure-workload-1" = {
      spoke_vnet_id               = module.secure_spoke_1.vnet_id
      spoke_vnet_name             = "vnet-secure-workload-1"
      spoke_resource_group_name   = "rg-secure-workload-1"
    }
    "secure-workload-2" = {
      spoke_vnet_id               = module.secure_spoke_2.vnet_id
      spoke_vnet_name             = "vnet-secure-workload-2"
      spoke_resource_group_name   = "rg-secure-workload-2"
    }
  }

  # Isolated configuration (no inter-spoke communication)
  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = false  # Isolate spokes from each other
    allow_gateway_transit        = true
    use_remote_gateways         = true
  }

  tags = {
    environment = "production"
    tier        = "networking-peering"
    security_level = "high"
    isolation = "enabled"
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
| azurerm.hub | ~> 3.0 |
| azurerm.spoke | ~> 3.0 |

## Resources

- `azurerm_virtual_network_peering.hub_to_spoke` (multiple)
- `azurerm_virtual_network_peering.spoke_to_hub` (multiple)

## Cross-Subscription Requirements

### Permissions
For cross-subscription peering, ensure the service principal or user has:
- **Network Contributor** role on both subscriptions
- Or custom role with `Microsoft.Network/virtualNetworks/virtualNetworkPeerings/*` permissions

### Provider Configuration
```hcl
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "spoke"
  subscription_id = var.spoke_subscription_id
  features {}
}
```

## Peering Limitations

### Azure Limits
- **Maximum peerings per VNet**: 500 (hub can connect to 500 spokes)
- **Address space overlap**: VNets cannot have overlapping CIDR blocks
- **Transitive routing**: Not supported (spoke-to-spoke requires hub routing)

### Gateway Transit Requirements
- Hub VNet must have a VPN Gateway or ExpressRoute Gateway
- Only one peered VNet can provide gateway services
- Spokes cannot have their own gateways when using remote gateways

## Troubleshooting

### Common Issues

1. **Peering State "Disconnected"**
   - Check if both peerings are created (bidirectional)
   - Verify address spaces don't overlap
   - Ensure proper permissions for cross-subscription peering

2. **Gateway Transit Not Working**
   - Verify hub has VPN/ExpressRoute Gateway
   - Check `allow_gateway_transit` is true on hub
   - Check `use_remote_gateways` is true on spoke
   - Ensure spoke doesn't have its own gateway

3. **Cross-Subscription Peering Fails**
   - Verify service principal has Network Contributor on both subscriptions
   - Check subscription IDs are correct
   - Ensure both VNets exist before creating peering

4. **Inter-Spoke Communication Issues**
   - Check `allow_forwarded_traffic` is enabled
   - Verify routing configuration in hub
   - Check Network Security Groups and route tables

### Monitoring Commands

```bash
# Check peering status
az network vnet peering list --resource-group rg-hub --vnet-name vnet-hub

# Show specific peering details
az network vnet peering show --name peer-hub-to-spoke --resource-group rg-hub --vnet-name vnet-hub

# Check effective routes (to verify gateway transit)
az network nic show-effective-route-table --name nic-name --resource-group rg-name
```

## Best Practices

1. **Naming Convention**: Use consistent naming for peering connections
2. **Address Planning**: Plan non-overlapping CIDR blocks
3. **Security**: Use NSGs and route tables for traffic control
4. **Monitoring**: Enable network monitoring and diagnostics
5. **Documentation**: Document peering relationships and dependencies
6. **Testing**: Test connectivity after peering creation
7. **Automation**: Use infrastructure as code for consistent deployment
