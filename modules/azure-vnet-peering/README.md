# Azure VNet Peering OpenTofu Module

A highly flexible and intelligent OpenTofu module for creating bidirectional VNet peering connections between a hub VNet and multiple spoke VNets, with smart defaults, conflict prevention, and comprehensive deployment insights.

## 🚀 Key Features

✅ **Minimal Required Input** - Only 3 variables needed (hub VNet information)  
✅ **Smart ALZ Defaults** - Azure Landing Zone optimized configuration out-of-the-box  
✅ **Conflict Prevention** - Random suffix generation prevents naming conflicts  
✅ **Comprehensive Validation** - Prevents common misconfigurations with clear error messages  
✅ **Auto-Tagging** - Rich metadata tagging for resource management  
✅ **Cross-Subscription Support** - Full support for hub-spoke across different subscriptions  
✅ **Enhanced Outputs** - Deployment summaries and connectivity troubleshooting guides  
✅ **Maximum Flexibility** - Every aspect configurable while maintaining simplicity  

## 🔧 Requirements

- OpenTofu >= 1.0
- Azure Provider >= 3.0
- Random Provider >= 3.1

## 📋 Quick Start

### Minimal Usage (Recommended)

```hcl
module "vnet_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Only required variables
  hub_vnet_id               = module.hub_networking[0].vnet_id
  hub_vnet_name             = module.hub_networking[0].vnet_name
  hub_resource_group_name   = module.hub_networking[0].networking_resource_group_name

  peering_connections = {
    "production" = {
      spoke_vnet_id               = module.spoke_networking["production"].vnet_id
      spoke_vnet_name             = module.spoke_networking["production"].vnet_name
      spoke_resource_group_name   = module.spoke_networking["production"].networking_resource_group_name
    }
    "development" = {
      spoke_vnet_id               = module.spoke_networking["development"].vnet_id
      spoke_vnet_name             = module.spoke_networking["development"].vnet_name
      spoke_resource_group_name   = module.spoke_networking["development"].networking_resource_group_name
    }
  }
  
  # All other settings use intelligent defaults:
  # ✅ ALZ-optimized peering configuration
  # ✅ Random suffixes for unique naming
  # ✅ Comprehensive auto-tagging
  # ✅ Gateway transit configuration
}
```

**What you get automatically:**
- Bidirectional peering between hub and all spokes
- ALZ-optimized configuration (gateway transit, forwarded traffic, etc.)
- Unique peering names with random suffixes
- Comprehensive metadata tagging
- Rich deployment summaries and connectivity guides

## 🎯 Smart Defaults

The module comes with Azure Landing Zone optimized defaults that work out-of-the-box:

### **Peering Configuration Defaults**
```hcl
peering_config = {
  allow_virtual_network_access = true   # VMs can communicate between hub and spokes
  allow_forwarded_traffic      = true   # Enable hub routing (spoke-to-spoke via hub)
  allow_gateway_transit        = true   # Hub provides gateway services (VPN/ExpressRoute)
  use_remote_gateways         = true   # Spokes use hub gateway for external connectivity
}
```

### **Naming Defaults**
```hcl
peering_name_prefix = "peer"           # Prefix for all peering connections
use_random_suffix   = true            # Prevents naming conflicts across deployments
```

### **Auto-Tagging Defaults**
```hcl
enable_auto_tagging = true            # Rich metadata tagging enabled
```

## 🔧 Configuration Examples

### 1. Basic Hub-Spoke (Uses All Defaults)

```hcl
module "basic_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  hub_vnet_id               = module.hub_networking.vnet_id
  hub_vnet_name             = "vnet-hub-connectivity"
  hub_resource_group_name   = "rg-hub-connectivity"

  peering_connections = {
    "workload" = {
      spoke_vnet_id               = module.spoke_networking["workload"].vnet_id
      spoke_vnet_name             = "vnet-spoke-workload"
      spoke_resource_group_name   = "rg-spoke-workload"
    }
  }
}
```

### 2. Custom Configuration

```hcl
module "custom_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  hub_vnet_id               = module.hub_networking.vnet_id
  hub_vnet_name             = "vnet-hub-connectivity"
  hub_resource_group_name   = "rg-hub-connectivity"

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
  }

  # Custom naming
  peering_name_prefix = "connect"
  use_random_suffix   = true

  # Custom peering configuration
  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic      = false  # Isolate spokes from each other
    allow_gateway_transit        = true
    use_remote_gateways         = true
  }

  # Custom tagging
  enable_auto_tagging = true
  tags = {
    environment = "production"
    project     = "alz-networking"
    owner       = "platform-team"
  }
}
```

### 3. Cross-Subscription Peering

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

  tags = {
    deployment_type = "cross-subscription"
    architecture    = "alz-hub-spoke"
  }
}
```

### 4. Isolated Spokes Configuration

```hcl
module "isolated_spokes" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  hub_vnet_id               = module.security_hub.vnet_id
  hub_vnet_name             = "vnet-security-hub"
  hub_resource_group_name   = "rg-security-hub"

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
    security_level = "high"
    isolation      = "enabled"
  }
}
```

## 📝 Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `hub_vnet_id` | ID of the hub virtual network | `string` |
| `hub_vnet_name` | Name of the hub virtual network | `string` |
| `hub_resource_group_name` | Resource group name of the hub virtual network | `string` |

### Core Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `peering_connections` | Map of spoke VNets to peer with the hub | `map(object)` | `{}` |
| `peering_config` | VNet peering configuration options | `object` | ALZ-optimized defaults |

### Naming Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `peering_name_prefix` | Prefix for peering connection names | `string` | `"peer"` |
| `use_random_suffix` | Add random suffix for uniqueness | `bool` | `true` |

### Tagging Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tags` | Tags to apply to all resources | `map(string)` | `{}` |
| `enable_auto_tagging` | Enable comprehensive auto-tagging | `bool` | `true` |

### Advanced Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `validate_gateway_consistency` | Enable gateway configuration validation | `bool` | `true` |

## 📤 Outputs

### Core Information

| Name | Description |
|------|-------------|
| `hub_to_spoke_peering_ids` | Map of hub to spoke peering IDs |
| `hub_to_spoke_peering_names` | Map of hub to spoke peering names |
| `spoke_to_hub_peering_ids` | Map of spoke to hub peering IDs |
| `spoke_to_hub_peering_names` | Map of spoke to hub peering names |
| `peering_status` | Status of all VNet peerings |

### Enhanced Information

| Name | Description |
|------|-------------|
| `peering_deployment_summary` | Complete deployment summary with configuration details |
| `connectivity_guide` | Comprehensive connectivity and troubleshooting guide |
| `all_peering_names` | All peering connection names created |
| `applied_tags` | Tags applied to resources (metadata only for peering) |
| `resource_names` | Names and patterns of all created resources |

### Legacy Compatibility

| Name | Description |
|------|-------------|
| `peering_summary` | Basic summary (backward compatibility) |

## 🎯 Peering Configuration Options

### Standard ALZ Configuration (Default)
```hcl
peering_config = {
  allow_virtual_network_access = true   # VMs can communicate
  allow_forwarded_traffic      = true   # Enable hub routing
  allow_gateway_transit        = true   # Hub provides gateway services
  use_remote_gateways         = true   # Spokes use hub gateway
}
```

### Isolated Spokes Configuration
```hcl
peering_config = {
  allow_virtual_network_access = true   # Hub-spoke communication
  allow_forwarded_traffic      = false  # Prevent inter-spoke traffic
  allow_gateway_transit        = true   # Hub provides gateway
  use_remote_gateways         = true   # Spokes use hub gateway
}
```

### No Gateway Transit Configuration
```hcl
peering_config = {
  allow_virtual_network_access = true   # VMs can communicate
  allow_forwarded_traffic      = true   # Allow traffic forwarding
  allow_gateway_transit        = false  # No gateway services
  use_remote_gateways         = false  # No remote gateway usage
}
```

## 🔍 Understanding Peering Settings

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

## 🏷️ Auto-Tagging Features

When `enable_auto_tagging = true` (default), the module automatically adds comprehensive metadata tags:

```hcl
auto_tags = {
  peering_type           = "hub-spoke"
  hub_vnet              = "vnet-hub-connectivity"
  spoke_count           = "3"
  gateway_transit       = "true"
  forwarded_traffic     = "true"
  virtual_network_access = "true"
  use_remote_gateways   = "true"
  creation_date         = "2025-01-15"
  creation_time         = "2025-01-15 16:30:45 CET"
  creation_method       = "OpenTofu"
  random_suffix_used    = "true"
}
```

**Note**: VNet peering resources don't support tags directly, but this metadata is available in outputs for resource management and documentation.

## 🔧 Naming and Conflict Prevention

### Smart Naming Pattern
```
{prefix}-{vnet1}-to-{vnet2}-{random}
```

### Examples
- `peer-vnet-hub-to-production-a1b2c3d4`
- `peer-production-to-vnet-hub-a1b2c3d4`
- `connect-hub-to-workload-x9y8z7w6` (custom prefix)

### Benefits
- **Unique across deployments**: Random suffixes prevent conflicts
- **Descriptive**: Clear indication of peering direction
- **Configurable**: Custom prefixes for organizational standards
- **Consistent**: Same suffix used for bidirectional peering pair

## 📊 Deployment Summary Output

The `peering_deployment_summary` output provides comprehensive deployment information:

```hcl
peering_deployment_summary = {
  architecture = "hub-spoke"
  hub_vnet = "vnet-hub-connectivity"
  total_peerings = 6  # 3 spokes × 2 directions
  spoke_vnets = ["production", "development", "dmz"]
  
  peering_configuration = {
    virtual_network_access = true
    forwarded_traffic = true
    gateway_transit = true
    use_remote_gateways = true
  }
  
  naming_configuration = {
    prefix = "peer"
    random_suffix = true
    suffix_used = "a1b2c3d4"
  }
  
  peering_names = {
    hub_to_spoke = {
      production = "peer-vnet-hub-to-production-a1b2c3d4"
      development = "peer-vnet-hub-to-development-a1b2c3d4"
      dmz = "peer-vnet-hub-to-dmz-a1b2c3d4"
    }
    spoke_to_hub = {
      production = "peer-production-to-vnet-hub-a1b2c3d4"
      development = "peer-development-to-vnet-hub-a1b2c3d4"
      dmz = "peer-dmz-to-vnet-hub-a1b2c3d4"
    }
  }
  
  auto_features = {
    auto_tagging_enabled = true
    random_suffix_used = true
    validation_enabled = true
  }
}
```

## 🔍 Connectivity Guide Output

The `connectivity_guide` output provides troubleshooting and understanding information:

```hcl
connectivity_guide = {
  hub_vnet = "vnet-hub-connectivity"
  architecture = "hub-spoke"
  
  connectivity_matrix = {
    production = {
      to_hub = "Enabled"
      from_hub = "Enabled"
      gateway_access = "Via Hub Gateway"
      traffic_forwarding = "Enabled (can route via hub)"
      virtual_network_access = "Enabled"
    }
    # ... other spokes
  }
  
  configuration_notes = [
    "✅ VMs can communicate between hub and spokes",
    "✅ Traffic can be forwarded through hub (enables spoke-to-spoke via hub routing)",
    "✅ Hub provides gateway services (VPN/ExpressRoute) to spokes",
    "✅ Spokes use hub gateway for external connectivity"
  ]
  
  troubleshooting = {
    peering_state_check = "Use 'az network vnet peering list' to check peering status"
    connectivity_test = "Test VM-to-VM connectivity to verify peering is working"
    routing_check = "Check effective routes on VM NICs to verify gateway transit"
    common_issues = [
      "Peering state 'Disconnected' - Check if both directions are created",
      "No connectivity - Verify NSGs and route tables",
      "Gateway transit not working - Ensure hub has VPN/ExpressRoute Gateway"
    ]
  }
  
  security_notes = [
    "Peering connections are not transitive - spokes cannot communicate directly",
    "Use NSGs and route tables for additional traffic control",
    "Monitor peering connections for unexpected traffic patterns",
    "Consider Azure Firewall in hub for centralized security"
  ]
}
```

## 🚨 Common Use Cases

### 1. Azure Landing Zone Hub-Spoke

```hcl
module "alz_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  hub_vnet_id               = module.hub_networking.vnet_id
  hub_vnet_name             = "vnet-hub-connectivity"
  hub_resource_group_name   = "rg-hub-connectivity"

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

  tags = {
    architecture = "alz-hub-spoke"
    environment = "production"
  }
}
```

### 2. Development Environment

```hcl
module "dev_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm
    azurerm.spoke = azurerm
  }

  hub_vnet_id               = module.dev_hub_networking.vnet_id
  hub_vnet_name             = "vnet-dev-hub"
  hub_resource_group_name   = "rg-dev-hub"

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
    auto_shutdown = "true"
  }
}
```

### 3. Multi-Region Hub-Spoke

```hcl
module "multi_region_peering" {
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  hub_vnet_id               = module.primary_hub.vnet_id
  hub_vnet_name             = "vnet-hub-primary"
  hub_resource_group_name   = "rg-hub-primary"

  peering_connections = {
    "secondary-hub" = {
      spoke_vnet_id               = module.secondary_hub.vnet_id
      spoke_vnet_name             = "vnet-hub-secondary"
      spoke_resource_group_name   = "rg-hub-secondary"
    }
    "workload-primary" = {
      spoke_vnet_id               = module.workload_primary.vnet_id
      spoke_vnet_name             = "vnet-workload-primary"
      spoke_resource_group_name   = "rg-workload-primary"
    }
    "workload-secondary" = {
      spoke_vnet_id               = module.workload_secondary.vnet_id
      spoke_vnet_name             = "vnet-workload-secondary"
      spoke_resource_group_name   = "rg-workload-secondary"
    }
  }

  tags = {
    architecture = "multi-region-hub-spoke"
    disaster_recovery = "enabled"
  }
}
```

## 🔒 Security Considerations

### Network Segmentation
- **Hub-spoke provides natural network segmentation**
- **Spokes are isolated from each other by default**
- **All inter-spoke traffic must route through hub**

### Gateway Transit Security
- **Centralized connectivity management in hub**
- **Spokes cannot bypass hub for external access**
- **Single point of control for VPN/ExpressRoute**

### Monitoring and Compliance
- **Comprehensive auto-tagging for resource tracking**
- **Rich outputs for compliance reporting**
- **Connectivity guides for security auditing**

## 🧹 Troubleshooting

### Common Issues

1. **Peering State "Disconnected"**
   ```bash
   # Check peering status
   az network vnet peering list --resource-group rg-hub --vnet-name vnet-hub
   ```
   - Verify both directions are created
   - Check address spaces don't overlap
   - Ensure proper permissions for cross-subscription peering

2. **Gateway Transit Not Working**
   ```bash
   # Check effective routes
   az network nic show-effective-route-table --name nic-name --resource-group rg-name
   ```
   - Verify hub has VPN/ExpressRoute Gateway
   - Check `allow_gateway_transit` is true on hub
   - Check `use_remote_gateways` is true on spoke

3. **Cross-Subscription Peering Fails**
   - Verify service principal has Network Contributor on both subscriptions
   - Check subscription IDs are correct
   - Ensure both VNets exist before creating peering

### Monitoring Commands

```bash
# List all peerings
az network vnet peering list --resource-group rg-hub --vnet-name vnet-hub

# Show specific peering details
az network vnet peering show --name peer-hub-to-spoke --resource-group rg-hub --vnet-name vnet-hub

# Check peering state
az network vnet peering list --resource-group rg-hub --vnet-name vnet-hub --query "[].{Name:name,State:peeringState}"
```

## 📋 Requirements

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

### Azure Limits
- **Maximum peerings per VNet**: 500 (hub can connect to 500 spokes)
- **Address space overlap**: VNets cannot have overlapping CIDR blocks
- **Transitive routing**: Not supported (spoke-to-spoke requires hub routing)

## 🎓 Best Practices

1. **Use Smart Defaults**: Let the module handle ALZ-optimized configuration
2. **Enable Random Suffixes**: Prevent naming conflicts across deployments
3. **Leverage Auto-Tagging**: Use comprehensive metadata for resource management
4. **Monitor Peering Health**: Use outputs for monitoring and troubleshooting
5. **Plan Address Spaces**: Ensure non-overlapping CIDR blocks
6. **Document Dependencies**: Use connectivity guides for team knowledge
7. **Test Connectivity**: Verify peering after deployment
8. **Security First**: Use NSGs and route tables for additional control

## 🔄 Migration from Previous Version

If upgrading from a previous version:

### What's New
- **Smart defaults eliminate need for explicit peering_config**
- **Random suffixes prevent naming conflicts**
- **Enhanced outputs provide rich deployment information**
- **Comprehensive validation prevents misconfigurations**

### Migration Steps
1. **Remove explicit peering_config** (unless customization needed)
2. **Add use_random_suffix = false** if you want to maintain existing names
3. **Review new outputs** for enhanced monitoring capabilities
4. **Update any automation** that depends on specific output formats

### Example Migration
**Before:**
```hcl
module "vnet_peering" {
  source = "./modules/azure-vnet-peering"
  
  hub_vnet_id = module.hub.vnet_id
  hub_vnet_name = module.hub.vnet_name
  hub_resource_group_name = module.hub.rg_name
  
  peering_connections = { ... }
  
  peering_config = {
    allow_virtual_network_access = true
    allow_forwarded_traffic = true
    allow_gateway_transit = true
    use_remote_gateways = true
  }
}
```

**After (minimal):**
```hcl
module "vnet_peering" {
  source = "./modules/azure-vnet-peering"
  
  hub_vnet_id = module.hub.vnet_id
  hub_vnet_name = module.hub.vnet_name
  hub_resource_group_name = module.hub.rg_name
  
  peering_connections = { ... }
  
  # peering_config uses smart defaults - no need to specify!
  # use_random_suffix = false  # Add this if you want to keep existing names
}
```

## 📚 Additional Resources

- [Azure VNet Peering Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Azure Landing Zone Hub-Spoke Architecture](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/hub-spoke-network-topology)
- [VNet Peering Limits and Considerations](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#networking-limits)
- [OpenTofu Documentation](https://opentofu.org/docs/)

## 🤝 Contributing

This module follows the MODULE-GENERALIZATION-GUIDE principles:
- Minimal required input with smart defaults
- Comprehensive validation and error handling
- Rich outputs and deployment guides
- Maximum configurability while maintaining simplicity
- Security-first design with intelligent defaults

When contributing:
- Maintain backward compatibility where possible
- Add comprehensive validation for new features
- Update outputs with relevant information
- Follow the established patterns for naming and tagging
- Include examples and documentation updates
