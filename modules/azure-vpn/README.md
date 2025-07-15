# Azure VPN OpenTofu Module

A highly flexible and intelligent OpenTofu module for creating Azure VPN Gateway infrastructure with smart defaults, flexible deployment modes, conflict prevention, and comprehensive deployment insights.

## 🚀 Key Features

✅ **Minimal Required Input** - Only 3 variables needed for gateway-only deployment  
✅ **Smart Production Defaults** - VpnGw1 SKU, RouteBased VPN, Generation1 out-of-the-box  
✅ **Flexible Deployment Modes** - Gateway-only or full site-to-site VPN  
✅ **Conflict Prevention** - Random suffix generation prevents naming conflicts  
✅ **Comprehensive Validation** - Prevents common misconfigurations with clear error messages  
✅ **Auto-Tagging** - Rich metadata tagging for resource management  
✅ **No Hardcoded Values** - Every aspect is configurable while maintaining simplicity  
✅ **Enhanced Outputs** - Deployment summaries and connectivity troubleshooting guides  
✅ **Multi-Site Ready** - Gateway-only mode supports multiple connections later  

## 🔧 Requirements

- OpenTofu >= 1.0
- Azure Provider >= 3.0
- Random Provider >= 3.1

## 📋 Quick Start

### Gateway-Only Deployment (Minimal)

```hcl
module "vpn_gateway" {
  source = "./modules/azure-vpn"

  # Only required variables
  resource_group_name = "rg-connectivity"
  gateway_subnet_id   = module.networking.subnet_ids["GatewaySubnet"]
  
  # All other settings use intelligent defaults:
  # ✅ VpnGw1 SKU for production readiness
  # ✅ RouteBased VPN for flexibility
  # ✅ Random suffixes for unique naming
  # ✅ Comprehensive auto-tagging
}
```

**What you get automatically:**
- Production-ready VPN Gateway with VpnGw1 SKU
- Unique resource names with random suffixes
- Comprehensive metadata tagging
- Smart Public IP configuration based on SKU
- Rich deployment summaries and connectivity guides

### Full Site-to-Site VPN

```hcl
module "vpn_site_to_site" {
  source = "./modules/azure-vpn"

  # Required variables
  resource_group_name = "rg-connectivity"
  gateway_subnet_id   = module.networking.subnet_ids["GatewaySubnet"]
  
  # Site-to-site configuration
  local_network_gateway = {
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16", "10.10.0.0/16"]
  }
  
  vpn_connection = {
    shared_key = "YourSecureSharedKey123!"
  }
  
  # All other settings use smart defaults automatically!
}
```

## 🎯 Smart Defaults

The module comes with production-ready defaults that work out-of-the-box:

### **VPN Gateway Defaults**
```hcl
vpn_gateway_sku       = "VpnGw1"        # Production-ready SKU
vpn_gateway_generation = "Generation1"   # Stable generation
vpn_type              = "RouteBased"     # Modern VPN type
enable_bgp            = false            # Simple by default
gateway_type          = "Vpn"           # VPN Gateway type
active_active         = false            # Single gateway by default
```

### **Naming Defaults**
```hcl
resource_name_prefix  = "vpn"           # Consistent naming prefix
use_random_suffix     = true            # Prevents naming conflicts
```

### **Auto-Tagging Defaults**
```hcl
enable_auto_tagging   = true            # Rich metadata tagging enabled
```

### **IP Configuration Defaults**
```hcl
ip_configuration_name = "vnetGatewayConfig"  # Standard configuration name
private_ip_address_allocation = "Dynamic"    # Dynamic IP allocation
```

## 🔧 Configuration Examples

### 1. Gateway-Only (Multi-Site Ready)

```hcl
module "hub_vpn_gateway" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-hub-connectivity"
  gateway_subnet_id   = module.hub_networking.subnet_ids["GatewaySubnet"]
  
  # Gateway-only mode - no local gateway or connection
  gateway_only_mode = true
  
  # Custom naming
  resource_name_prefix = "hub"
  
  tags = {
    environment = "production"
    tier        = "connectivity"
    role        = "hub-vpn"
  }
}
```

### 2. High-Performance VPN with BGP

```hcl
module "high_perf_vpn" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-connectivity"
  gateway_subnet_id   = module.networking.subnet_ids["GatewaySubnet"]
  
  # High-performance configuration
  vpn_gateway_sku        = "VpnGw3"
  vpn_gateway_generation = "Generation2"
  enable_bgp            = true
  
  bgp_settings = {
    asn         = 65001
    peer_weight = 10
  }
  
  local_network_gateway = {
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16"]
  }
  
  vpn_connection = {
    shared_key          = var.vpn_shared_key
    connection_protocol = "IKEv2"
    ipsec_policy = {
      dh_group         = "DHGroup24"
      ike_encryption   = "AES256"
      ike_integrity    = "SHA384"
      ipsec_encryption = "AES256"
      ipsec_integrity  = "SHA256"
      pfs_group        = "PFS24"
      sa_lifetime      = 7200
    }
  }
  
  tags = {
    environment = "production"
    performance = "high"
    bgp_enabled = "true"
  }
}
```

### 3. Active-Active High Availability

```hcl
module "ha_vpn" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-connectivity"
  gateway_subnet_id   = module.networking.subnet_ids["GatewaySubnet"]
  
  # High availability configuration
  vpn_gateway_sku = "VpnGw2"  # Required for active-active
  active_active   = true
  
  local_network_gateway = {
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16"]
  }
  
  vpn_connection = {
    shared_key = var.vpn_shared_key
  }
  
  tags = {
    environment = "production"
    availability = "high"
  }
}
```

### 4. ExpressRoute Gateway

```hcl
module "expressroute_gateway" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-connectivity"
  gateway_subnet_id   = module.networking.subnet_ids["GatewaySubnet"]
  
  # ExpressRoute configuration
  gateway_type        = "ExpressRoute"
  vpn_gateway_sku     = "Standard"  # ExpressRoute SKU
  
  # No local gateway or connection for ExpressRoute
  gateway_only_mode = true
  
  tags = {
    environment = "production"
    connectivity = "expressroute"
  }
}
```

### 5. Development Environment

```hcl
module "dev_vpn" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-dev-connectivity"
  gateway_subnet_id   = module.dev_networking.subnet_ids["GatewaySubnet"]
  location           = "North Europe"
  
  # Cost-effective for development
  vpn_gateway_sku = "Basic"
  
  local_network_gateway = {
    gateway_address = "203.0.113.100"
    address_space   = ["172.16.0.0/16"]
  }
  
  vpn_connection = {
    shared_key = var.dev_vpn_shared_key
  }
  
  tags = {
    environment = "development"
    cost_center = "dev-ops"
    auto_shutdown = "true"
  }
}
```

## 📝 Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Name of the resource group for VPN resources | `string` |
| `gateway_subnet_id` | ID of the GatewaySubnet where VPN Gateway will be deployed | `string` |

### Core Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `location` | Azure region where VPN resources will be created | `string` | `"West Europe"` |
| `local_network_gateway` | Configuration for the local network gateway (on-premises) | `object` | `null` |
| `vpn_connection` | Configuration for the VPN connection | `object` | `null` |

### VPN Gateway Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpn_gateway_name` | Name of the VPN Gateway (auto-generated if null) | `string` | `null` |
| `vpn_gateway_sku` | SKU of the VPN Gateway | `string` | `"VpnGw1"` |
| `vpn_gateway_generation` | Generation of the VPN Gateway | `string` | `"Generation1"` |
| `vpn_type` | Type of VPN (RouteBased or PolicyBased) | `string` | `"RouteBased"` |
| `gateway_type` | Type of virtual network gateway (Vpn or ExpressRoute) | `string` | `"Vpn"` |
| `active_active` | Enable active-active configuration | `bool` | `false` |

### BGP Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_bgp` | Enable BGP for the VPN Gateway | `bool` | `false` |
| `bgp_settings` | BGP settings for the VPN Gateway | `object` | `{asn=65515, peer_weight=0}` |

### Naming Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `resource_name_prefix` | Prefix for all resource names | `string` | `"vpn"` |
| `use_random_suffix` | Add random suffix for uniqueness | `bool` | `true` |

### IP Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ip_configuration_name` | Name for the IP configuration | `string` | `"vnetGatewayConfig"` |
| `private_ip_address_allocation` | Private IP allocation method | `string` | `"Dynamic"` |
| `public_ip_allocation_method` | Public IP allocation method (auto-determined) | `string` | `null` |
| `public_ip_sku` | Public IP SKU (auto-determined) | `string` | `null` |

### Advanced Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `gateway_only_mode` | Deploy only VPN Gateway without connection | `bool` | `false` |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` |
| `enable_auto_tagging` | Enable comprehensive auto-tagging | `bool` | `true` |

## 📤 Outputs

### Core Information

| Name | Description |
|------|-------------|
| `vpn_gateway_id` | ID of the VPN Gateway |
| `vpn_gateway_name` | Name of the VPN Gateway |
| `vpn_gateway_public_ip` | Public IP address of the VPN Gateway |
| `vpn_gateway_sku` | SKU of the VPN Gateway |
| `vpn_gateway_type` | Type of the VPN Gateway |
| `vpn_gateway_generation` | Generation of the VPN Gateway |

### Connection Information (Conditional)

| Name | Description |
|------|-------------|
| `local_network_gateway_id` | ID of the Local Network Gateway (null if not created) |
| `local_network_gateway_name` | Name of the Local Network Gateway (null if not created) |
| `vpn_connection_id` | ID of the VPN Connection (null if not created) |
| `vpn_connection_name` | Name of the VPN Connection (null if not created) |
| `vpn_connection_status` | Status of the VPN Connection |

### BGP Information (Conditional)

| Name | Description |
|------|-------------|
| `bgp_settings` | BGP settings of the VPN Gateway (null if BGP disabled) |

### Enhanced Information

| Name | Description |
|------|-------------|
| `vpn_deployment_summary` | Complete deployment summary with configuration details |
| `connectivity_guide` | Comprehensive connectivity and troubleshooting guide |
| `deployment_mode_info` | Information about deployment mode and capabilities |
| `applied_tags` | Tags applied to all VPN resources |
| `resource_names` | Names of all created VPN resources |

### Legacy Compatibility

| Name | Description |
|------|-------------|
| `vpn_summary` | Basic summary (backward compatibility) |

## 🎯 VPN Gateway SKUs and Capabilities

### Basic SKU
- **Throughput**: 100 Mbps
- **Tunnels**: 10
- **BGP**: Not supported
- **Active-Active**: Not supported
- **Use Case**: Development, testing

### Standard SKUs
| SKU | Throughput | Tunnels | BGP | Active-Active | Generation |
|-----|------------|---------|-----|---------------|------------|
| VpnGw1 | 650 Mbps | 30 | Yes | Yes | Gen1/Gen2 |
| VpnGw2 | 1 Gbps | 30 | Yes | Yes | Gen1/Gen2 |
| VpnGw3 | 1.25 Gbps | 30 | Yes | Yes | Gen1/Gen2 |
| VpnGw4 | 5 Gbps | 100 | Yes | Yes | Gen2 only |
| VpnGw5 | 10 Gbps | 100 | Yes | Yes | Gen2 only |

### Availability Zone SKUs
- **VpnGw1AZ** through **VpnGw5AZ**
- Zone-redundant deployment
- Higher availability and resilience
- Same performance as standard SKUs

## 🔄 Deployment Modes

### 1. Gateway-Only Mode
```hcl
# Deploy VPN Gateway without local gateway or connection
gateway_only_mode = true
# OR
local_network_gateway = null
vpn_connection = null
```

**Use Cases:**
- Multi-site VPN scenarios
- ExpressRoute coexistence
- Prepare infrastructure before configuring connections
- Hub VPN Gateway in hub-spoke architecture

### 2. Full Site-to-Site Mode
```hcl
# Deploy complete VPN setup
local_network_gateway = {
  gateway_address = "203.0.113.12"
  address_space   = ["192.168.0.0/16"]
}

vpn_connection = {
  shared_key = "YourSecureSharedKey123!"
}
```

**Use Cases:**
- Single site-to-site VPN
- Branch office connectivity
- Simple VPN scenarios

## 🏷️ Auto-Tagging Features

When `enable_auto_tagging = true` (default), the module automatically adds comprehensive metadata tags:

```hcl
auto_tags = {
  vpn_gateway_name      = "vpn-gateway-a1b2c3d4"
  vpn_gateway_sku       = "VpnGw1"
  vpn_gateway_generation = "Generation1"
  vpn_type              = "RouteBased"
  bgp_enabled           = "false"
  deployment_mode       = "full-site-to-site"
  local_gateway_created = "true"
  connection_created    = "true"
  creation_date         = "2025-01-15"
  creation_time         = "2025-01-15 16:30:45 CET"
  creation_method       = "OpenTofu"
  random_suffix_used    = "true"
}
```

## 🔧 Naming and Conflict Prevention

### Smart Naming Pattern
```
{prefix}-{resource-type}-{random}
```

### Examples
- `vpn-gateway-a1b2c3d4`
- `vpn-local-gateway-a1b2c3d4`
- `vpn-connection-a1b2c3d4`
- `hub-gateway-x9y8z7w6` (custom prefix)

### Benefits
- **Unique across deployments**: Random suffixes prevent conflicts
- **Descriptive**: Clear indication of resource purpose
- **Configurable**: Custom prefixes for organizational standards
- **Consistent**: Same suffix used for related resources

## 📊 Deployment Summary Output

The `vpn_deployment_summary` output provides comprehensive deployment information:

```hcl
vpn_deployment_summary = {
  deployment_mode = "full-site-to-site"
  
  vpn_gateway = {
    name       = "vpn-gateway-a1b2c3d4"
    sku        = "VpnGw1"
    generation = "Generation1"
    type       = "RouteBased"
    public_ip  = "20.123.45.67"
    bgp_enabled = false
  }
  
  local_network_gateway = {
    name            = "vpn-local-gateway-a1b2c3d4"
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16"]
  }
  
  vpn_connection = {
    name                = "vpn-connection-a1b2c3d4"
    connection_protocol = "IKEv2"
    ipsec_policy_used   = false
  }
  
  naming_configuration = {
    prefix            = "vpn"
    random_suffix     = true
    suffix_used       = "-a1b2c3d4"
  }
}
```

## 🔍 Connectivity Guide Output

The `connectivity_guide` output provides troubleshooting and understanding information:

```hcl
connectivity_guide = {
  deployment_mode = "full-site-to-site"
  vpn_gateway_public_ip = "20.123.45.67"
  
  connection_info = {
    azure_gateway_ip    = "20.123.45.67"
    on_premises_ip      = "203.0.113.12"
    on_premises_networks = ["192.168.0.0/16"]
    connection_protocol = "IKEv2"
    ipsec_policy_custom = false
  }
  
  configuration_notes = [
    "VPN Gateway SKU: VpnGw1 (Generation1)",
    "VPN Type: RouteBased",
    "❌ BGP disabled - using static routing",
    "❌ Using default IPSec policy"
  ]
  
  troubleshooting = {
    common_commands = [
      "az network vnet-gateway show --name vpn-gateway-a1b2c3d4 --resource-group rg-connectivity",
      "az network vpn-connection show --name vpn-connection-a1b2c3d4 --resource-group rg-connectivity"
    ]
    
    common_issues = [
      "Gateway creation timeout - VPN Gateway creation can take 30-45 minutes",
      "Connection not established - Check shared key and on-premises configuration",
      "Routing issues - Check route tables and BGP advertisements"
    ]
  }
}
```

## 🚨 Common Use Cases

### 1. Azure Landing Zone Hub VPN

```hcl
module "alz_hub_vpn" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-hub-connectivity"
  gateway_subnet_id   = module.hub_networking.subnet_ids["GatewaySubnet"]
  
  # Hub gateway configuration
  resource_name_prefix = "hub"
  vpn_gateway_sku     = "VpnGw2"
  enable_bgp          = true
  
  bgp_settings = {
    asn = 65515
  }
  
  local_network_gateway = {
    gateway_address = var.headquarters_public_ip
    address_space   = var.headquarters_networks
  }
  
  vpn_connection = {
    shared_key = var.vpn_shared_key
  }
  
  tags = {
    architecture = "alz-hub-spoke"
    environment = "production"
    tier        = "connectivity"
  }
}
```

### 2. Branch Office VPN

```hcl
module "branch_vpn" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-branch-connectivity"
  gateway_subnet_id   = module.branch_networking.subnet_ids["GatewaySubnet"]
  location           = "North Europe"
  
  # Cost-effective for branch
  vpn_gateway_sku = "Basic"
  
  local_network_gateway = {
    gateway_address = var.headquarters_public_ip
    address_space   = ["10.0.0.0/16"]
  }
  
  vpn_connection = {
    shared_key = var.branch_vpn_shared_key
  }
  
  tags = {
    environment = "production"
    role        = "branch-connectivity"
    cost_center = "branch-operations"
  }
}
```

### 3. Multi-Site Hub Gateway

```hcl
module "multisite_hub" {
  source = "./modules/azure-vpn"

  resource_group_name = "rg-multisite-connectivity"
  gateway_subnet_id   = module.multisite_networking.subnet_ids["GatewaySubnet"]
  
  # Gateway-only for multi-site
  gateway_only_mode = true
  
  # High-performance for multiple connections
  vpn_gateway_sku = "VpnGw3"
  enable_bgp      = true
  
  bgp_settings = {
    asn         = 65001
    peer_weight = 10
  }
  
  tags = {
    environment = "production"
    role        = "multisite-hub"
    connections = "multiple"
  }
}
```

## 🔒 Security Considerations

### VPN Configuration Security
- **Use strong shared keys** (minimum 8 characters, recommended 20+)
- **Consider custom IPSec policies** for enhanced security
- **Implement BGP authentication** when possible
- **Monitor VPN Gateway logs** for security events

### Network Security
- **Use Network Security Groups** for additional traffic control
- **Implement proper routing** to limit access
- **Monitor connection status** and traffic patterns
- **Regularly rotate shared keys** and certificates

### Access Control
- **Use Azure RBAC** for VPN Gateway management
- **Implement proper resource group** permissions
- **Monitor configuration changes** through Azure Activity Log
- **Use Azure Policy** for compliance enforcement

## 🧹 Troubleshooting

### Common Issues

1. **VPN Gateway Creation Timeout**
   ```bash
   # VPN Gateway creation can take 30-45 minutes
   # Check deployment status
   az deployment group show --name terraform-deployment --resource-group rg-connectivity
   ```

2. **Connection Not Established**
   ```bash
   # Check connection status
   az network vpn-connection show --name connection-name --resource-group rg-name
   ```
   - Verify shared key matches on both sides
   - Check on-premises VPN device configuration
   - Verify address spaces don't overlap

3. **BGP Not Working**
   ```bash
   # Check BGP peer status
   az network vnet-gateway list-bgp-peer-status --name gateway-name --resource-group rg-name
   ```
   - Verify ASN numbers don't conflict
   - Check BGP configuration on both sides
   - Ensure BGP is supported on chosen SKU

4. **Performance Issues**
   - Consider upgrading VPN Gateway SKU
   - Check for network congestion
   - Verify IPSec policy compatibility
   - Monitor gateway metrics

### Monitoring Commands

```bash
# Check VPN Gateway status
az network vnet-gateway show --name vpn-gateway-name --resource-group rg-name

# Check connection status
az network vpn-connection show --name connection-name --resource-group rg-name

# List all connections
az network vpn-connection list --resource-group rg-name

# Check BGP peer status (if BGP enabled)
az network vnet-gateway list-bgp-peer-status --name gateway-name --resource-group rg-name

# Check effective routes
az network nic show-effective-route-table --name nic-name --resource-group rg-name
```

## 📋 Requirements and Limits

### Azure Limits
- **Maximum connections per gateway**: Varies by SKU (10-100)
- **Maximum throughput**: Varies by SKU (100 Mbps - 10 Gbps)
- **BGP support**: Not available on Basic SKU
- **Active-Active**: Requires VpnGw2 or higher

### Permissions Required
- **Network Contributor** role on resource group
- **Virtual Machine Contributor** for gateway subnet access
- **Custom role** with specific VPN Gateway permissions

### Network Requirements
- **GatewaySubnet**: Must exist in target VNet
- **Address space**: No overlapping CIDR blocks
- **Public IP**: Required for VPN Gateway
- **On-premises device**: Must support IPSec/IKE

## 🎓 Best Practices

1. **Use Smart Defaults**: Let the module handle production-ready configuration
2. **Enable Random Suffixes**: Prevent naming conflicts across deployments
3. **Leverage Auto-Tagging**: Use comprehensive metadata for resource management
4. **Monitor Gateway Health**: Use outputs for monitoring and troubleshooting
5. **Plan Address Spaces**: Ensure non-overlapping CIDR blocks
6. **Choose Appropriate SKU**: Balance cost and performance requirements
7. **Use BGP When Possible**: For dynamic routing and better failover
8. **Implement Proper Security**: Strong shared keys and custom IPSec policies

## 🔄 Migration from Previous Version

If upgrading from a previous version:

### What's New
- **Minimal required input** (only 3 variables for gateway-only)
- **Smart defaults** eliminate need for explicit configuration
- **Random suffixes** prevent naming conflicts
- **Enhanced outputs** provide rich deployment information
- **Flexible deployment modes** (gateway-only vs full site-to-site)
- **No hardcoded values** - everything is configurable

### Migration Steps
1. **Review new variable structure** - many are now optional with defaults
2. **Add use_random_suffix = false** if you want to maintain existing names
3. **Review new outputs** for enhanced monitoring capabilities
4. **Update any automation** that depends on specific output formats

### Example Migration
**Before:**
```hcl
module "vpn" {
  source = "./modules/azure-vpn"
  
  vpn_gateway_name    = "vpn-gateway-main"
  resource_group_name = "rg-connectivity"
  location            = "West Europe"
  gateway_subnet_id   = var.gateway_subnet_id
  
  vpn_gateway_sku = "VpnGw1"
  vpn_type        = "RouteBased"
  
  local_network_gateway = { ... }
  vpn_connection = { ... }
}
```

**After (minimal):**
```hcl
module "vpn" {
  source = "./modules/azure-vpn"
  
  # Only required variables
  resource_group_name = "rg-connectivity"
  gateway_subnet_id   = var.gateway_subnet_id
  
  # Optional: maintain existing name
  vpn_gateway_name = "vpn-gateway-main"
  use_random_suffix = false
  
  # Optional: site-to-site configuration
  local_network_gateway = { ... }
  vpn_connection = { ... }
  
  # All other settings use smart defaults!
}
```

## 📚 Additional Resources

- [Azure VPN Gateway Documentation](https://docs.microsoft.com/en-us/azure/vpn-gateway/)
- [VPN Gateway SKUs and Performance](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways#gwsku)
- [BGP with Azure VPN Gateway](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-bgp-overview)
- [IPSec/IKE Policy Configuration](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-ipsecikepolicy-rm-powershell)
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
