# Azure Networking OpenTofu Module

A highly flexible and comprehensive OpenTofu module for deploying Azure Virtual Networks with advanced configuration options and sensible defaults.

## 🚀 Key Features

✅ **Minimal Required Input** - Only `resource_group_name` and `vnet_name` required  
✅ **Smart Subnet Management** - Automatic CIDR calculation with single default subnet  
✅ **Advanced VNet Configuration** - DNS servers, DDoS protection, BGP community, encryption  
✅ **Comprehensive Subnet Features** - Service endpoints, delegations, NSG/route table associations  
✅ **Gateway Subnet Support** - Automatic GatewaySubnet creation for VPN/ExpressRoute  
✅ **Flexible Architecture** - Supports simple networks to complex hub-spoke designs  
✅ **Comprehensive Outputs** - Detailed outputs including calculated CIDRs and deployment info  

## 🔧 Requirements

- OpenTofu >= 1.0
- Azure Provider >= 3.0

## 📋 Quick Start

### Minimal Usage (Only required variables)

```hcl
module "network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-networking-prod"
  vnet_name          = "vnet-prod"
}
```

**What you get:**
- Resource group: `rg-networking-prod`
- VNet: `vnet-prod` with CIDR `10.0.0.0/20`
- Single subnet: `default` with auto-calculated CIDR
- Location: `West Europe`
- Azure default DNS servers
- **No NSGs created** (users must explicitly request NSG creation)
- Comprehensive auto-tagging

## 🏗️ Usage Examples

### Simple Network

```hcl
module "simple_network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-networking-simple"
  vnet_name          = "vnet-simple"
  vnet_cidr          = "10.1.0.0/20"
  subnet_names       = ["subnet-app", "subnet-db"]
}
```

### Hub Network (ALZ Pattern)

```hcl
module "hub_network" {
  source = "./modules/azure-networking"
  
  resource_group_name   = "rg-hub-connectivity"
  vnet_name            = "vnet-hub"
  vnet_cidr            = "10.0.0.0/20"
  location             = "North Europe"
  
  # Hub-specific subnets
  subnet_names         = ["AzureFirewallSubnet", "ManagementSubnet"]
  create_gateway_subnet = true
  
  # Custom DNS servers
  dns_servers = ["10.0.0.4", "10.0.0.5"]
}
```

### Spoke Network with Advanced Features

```hcl
module "spoke_network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-spoke-workload"
  vnet_name          = "vnet-spoke-workload"
  vnet_cidr          = "10.1.0.0/20"
  
  subnet_names = ["subnet-web", "subnet-app", "subnet-db"]
  
  # Service endpoints for specific subnets
  subnet_service_endpoints = {
    "subnet-app" = ["Microsoft.Storage", "Microsoft.KeyVault"]
    "subnet-db"  = ["Microsoft.Sql", "Microsoft.Storage"]
  }
  
  # Subnet delegations
  subnet_delegations = {
    "subnet-app" = {
      name = "app-delegation"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}
```

### Production Network with Created NSGs

```hcl
module "prod_network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-networking-prod"
  vnet_name          = "vnet-prod"
  vnet_cidr          = "10.2.0.0/16"
  
  subnet_names = ["subnet-web", "subnet-app", "subnet-db"]
  
  # Create NSGs for specific subnets
  create_subnet_nsgs = {
    "subnet-web" = true
    "subnet-app" = true
  }
  
  # Define NSG rules for each subnet
  subnet_nsg_rules = {
    "subnet-web" = [
      {
        name                       = "AllowHTTPS"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "AllowHTTP"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
    "subnet-app" = [
      {
        name                       = "AllowAppPort"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "10.2.0.0/24"  # From web subnet
        destination_address_prefix = "*"
      }
    ]
  }
  
  # Custom subnet sizing
  subnet_newbits = 8  # Creates /24 subnets from /16 VNet
}
```

### Network with External NSG Associations

```hcl
# First create NSGs (outside this module)
resource "azurerm_network_security_group" "external_nsg" {
  name                = "nsg-external"
  location            = "West Europe"
  resource_group_name = "rg-security"
}

# Then create network with external NSG associations
module "network_with_external_nsg" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-networking-prod"
  vnet_name          = "vnet-prod"
  subnet_names       = ["subnet-web", "subnet-app"]
  
  # Associate external NSGs with subnets
  subnet_nsg_associations = {
    "subnet-web" = azurerm_network_security_group.external_nsg.id
  }
}
```

## 📝 Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Name of the resource group for networking resources | `string` |
| `vnet_name` | Name of the virtual network | `string` |

### Core Configuration (Optional with Defaults)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `location` | Azure region where resources will be created | `string` | `"West Europe"` |
| `vnet_cidr` | CIDR block for the virtual network | `string` | `"10.0.0.0/20"` |
| `subnet_names` | List of subnet names to create | `list(string)` | `["default"]` |
| `subnet_newbits` | Additional bits to extend VNet prefix for subnets | `number` | `4` |

### Gateway Subnet Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_gateway_subnet` | Whether to create a GatewaySubnet | `bool` | `false` |
| `gateway_subnet_newbits` | Additional bits for the GatewaySubnet | `number` | `4` |

### Advanced VNet Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `dns_servers` | List of DNS servers for the VNet | `list(string)` | `[]` |
| `ddos_protection_plan_id` | ID of the DDoS protection plan | `string` | `null` |
| `flow_timeout_in_minutes` | Flow timeout in minutes | `number` | `4` |
| `bgp_community` | BGP community attribute | `string` | `null` |
| `encryption` | VNet encryption setting | `string` | `"AllowUnencrypted"` |

### Subnet Advanced Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `subnet_service_endpoints` | Map of subnet names to service endpoints | `map(list(string))` | `{}` |
| `subnet_service_endpoint_policies` | Map of subnet names to service endpoint policies | `map(list(string))` | `{}` |
| `subnet_delegations` | Map of subnet names to delegation configurations | `map(object)` | `{}` |
| `subnet_private_endpoint_network_policies_enabled` | Enable/disable private endpoint policies per subnet | `map(bool)` | `{}` |
| `subnet_private_link_service_network_policies_enabled` | Enable/disable private link service policies per subnet | `map(bool)` | `{}` |

### Network Security Group Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_subnet_nsgs` | Map of subnet names to create NSGs for | `map(bool)` | `{}` |
| `subnet_nsg_rules` | Map of subnet names to their NSG rules | `map(list(object))` | `{}` |
| `subnet_nsg_associations` | Map of subnet names to external NSG IDs | `map(string)` | `{}` |
| `nsg_name_prefix` | Prefix for NSG resource names | `string` | `"nsg"` |

### Route Table Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `subnet_route_table_associations` | Map of subnet names to route table IDs | `map(string)` | `{}` |

### Tagging Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tags` | Tags to apply to all resources | `map(string)` | `{}` |
| `enable_auto_tagging` | Enable comprehensive auto-tagging | `bool` | `true` |
| `subnet_tags` | Map of subnet names to specific tags | `map(map(string))` | `{}` |

## 📤 Outputs

### Core Network Information

| Name | Description |
|------|-------------|
| `vnet_id` | Virtual network ID |
| `vnet_name` | Virtual network name |
| `vnet_address_space` | Virtual network address space |
| `networking_resource_group_name` | Resource group name |
| `subnet_ids` | Map of subnet names to IDs |
| `subnet_names` | List of subnet names |

### Gateway Subnet

| Name | Description |
|------|-------------|
| `gateway_subnet_id` | GatewaySubnet ID (if created) |
| `gateway_subnet_address_prefix` | GatewaySubnet address prefix |

### Advanced Information

| Name | Description |
|------|-------------|
| `network_summary` | Comprehensive network configuration summary |
| `calculated_subnet_cidrs` | Map of subnet names to calculated CIDRs |
| `available_ip_addresses` | Approximate available IPs per subnet |
| `deployment_info` | Deployment information and feature status |

### Associations

| Name | Description |
|------|-------------|
| `nsg_associations` | NSG associations per subnet |
| `route_table_associations` | Route table associations per subnet |
| `subnet_service_endpoints` | Service endpoints per subnet |

## 🔧 Advanced Features

### Automatic CIDR Calculation

The module automatically calculates subnet CIDRs using the `cidrsubnets` function:

```hcl
# VNet: 10.0.0.0/20 with subnet_newbits = 4 creates /24 subnets:
# subnet-web: 10.0.0.0/24
# subnet-app: 10.0.1.0/24  
# subnet-db:  10.0.2.0/24
# GatewaySubnet: 10.0.15.0/24 (last available)
```

### Service Endpoints

Configure Azure service endpoints for secure access:

```hcl
subnet_service_endpoints = {
  "subnet-app" = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
  "subnet-db" = [
    "Microsoft.Sql",
    "Microsoft.Storage"
  ]
}
```

### Subnet Delegations

Delegate subnets to Azure services:

```hcl
subnet_delegations = {
  "subnet-aci" = {
    name = "aci-delegation"
    service_delegation = {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
```

### NSG and Route Table Associations

Associate existing NSGs and route tables:

```hcl
subnet_nsg_associations = {
  "subnet-web" = azurerm_network_security_group.web.id
  "subnet-app" = azurerm_network_security_group.app.id
}

subnet_route_table_associations = {
  "subnet-web" = azurerm_route_table.web.id
}
```

## 🏗️ Architecture Patterns

### Hub-Spoke ALZ Pattern

```hcl
# Hub Network
module "hub" {
  source = "./modules/azure-networking"
  
  resource_group_name   = "rg-hub-connectivity"
  vnet_name            = "vnet-hub"
  vnet_cidr            = "10.0.0.0/20"
  subnet_names         = ["AzureFirewallSubnet", "ManagementSubnet"]
  create_gateway_subnet = true
}

# Production Spoke
module "spoke_prod" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-spoke-prod"
  vnet_name          = "vnet-spoke-prod"
  vnet_cidr          = "10.1.0.0/20"
  subnet_names       = ["subnet-web", "subnet-app", "subnet-db"]
}

# Development Spoke
module "spoke_dev" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-spoke-dev"
  vnet_name          = "vnet-spoke-dev"
  vnet_cidr          = "10.2.0.0/20"
  subnet_names       = ["subnet-dev-app", "subnet-dev-db"]
}
```

### Single VNet Pattern

```hcl
module "single_network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-networking-single"
  vnet_name          = "vnet-single"
  vnet_cidr          = "10.0.0.0/16"
  
  subnet_names = [
    "subnet-web",
    "subnet-app", 
    "subnet-db",
    "subnet-mgmt"
  ]
  
  create_gateway_subnet = true
  subnet_newbits       = 8  # /24 subnets
}
```

## 🔒 Security Best Practices

### 1. Network Segmentation
- Use separate subnets for different tiers (web, app, db)
- Implement NSGs at subnet level for traffic control
- Use service endpoints for secure Azure service access

### 2. Gateway Subnet Placement
- GatewaySubnet is automatically placed at the end of address space
- Ensures no conflicts with regular subnets
- Proper sizing for VPN/ExpressRoute requirements

### 3. DNS Configuration
- Use custom DNS servers for hybrid connectivity
- Configure conditional forwarding for on-premises resolution
- Implement DNS security policies

## 🎯 Use Cases

### Development Environment
```hcl
module "dev_network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-dev-networking"
  vnet_name          = "vnet-dev"
  vnet_cidr          = "10.10.0.0/20"
  subnet_names       = ["subnet-dev-app"]
}
```

### Production Multi-Tier
```hcl
module "prod_network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-prod-networking"
  vnet_name          = "vnet-prod"
  vnet_cidr          = "10.0.0.0/16"
  
  subnet_names = [
    "subnet-web",
    "subnet-app",
    "subnet-db",
    "subnet-mgmt"
  ]
  
  subnet_newbits = 8  # /24 subnets for better segmentation
  
  subnet_service_endpoints = {
    "subnet-app" = ["Microsoft.Storage", "Microsoft.KeyVault"]
    "subnet-db"  = ["Microsoft.Sql"]
  }
}
```

### Hub Connectivity
```hcl
module "hub_network" {
  source = "./modules/azure-networking"
  
  resource_group_name   = "rg-hub-connectivity"
  vnet_name            = "vnet-hub"
  vnet_cidr            = "10.0.0.0/20"
  
  subnet_names = [
    "AzureFirewallSubnet",
    "ManagementSubnet"
  ]
  
  create_gateway_subnet = true
  dns_servers          = ["10.0.0.4", "10.0.0.5"]
}
```

## 🔄 Migration from Previous Version

The generalized module maintains backward compatibility:

**Old approach:**
```hcl
module "network" {
  source = "./modules/azure-networking"
  
  vnet_name           = "vnet-prod"
  resource_group_name = "rg-networking"
  location            = "West Europe"
  vnet_cidr           = "10.0.0.0/20"
  subnet_names        = ["subnet-web", "subnet-app"]
}
```

**New approach (same result):**
```hcl
module "network" {
  source = "./modules/azure-networking"
  
  resource_group_name = "rg-networking"  # Still required
  vnet_name          = "vnet-prod"       # Still required
  # location defaults to "West Europe"
  # vnet_cidr defaults to "10.0.0.0/20"
  subnet_names       = ["subnet-web", "subnet-app"]
}
```

## 📚 Additional Resources

- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Landing Zone Network Topology](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/traditional-azure-networking-topology)
- [OpenTofu Documentation](https://opentofu.org/docs/)

## 🤝 Contributing

This module follows infrastructure-as-code best practices:
- Comprehensive variable validation
- Detailed documentation and examples
- Backward compatibility maintenance
- Security-first design principles
