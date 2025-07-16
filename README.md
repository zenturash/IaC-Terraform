# Azure Landing Zone (ALZ) OpenTofu Module

A flexible OpenTofu module for deploying Azure infrastructure with support for both single VNet and Azure Landing Zone (ALZ) hub-spoke architectures. Built following generalization best practices for security-first design, minimal required input, and maximum flexibility.

## 🏗️ Architecture Support

### Single VNet (Original)
- All resources in one VNet
- Simple deployment model
- Backward compatible

### Hub-Spoke ALZ
- Dedicated hub VNet for connectivity (VPN, ExpressRoute)
- Separate spoke VNets for workloads
- VNet peering between hub and spokes
- Centralized connectivity management
- Multi-subscription support

## 🚀 Features

- **Dual Architecture Support**: Choose between single-vnet or hub-spoke ALZ
- **Generalized Modules**: Security-first design with minimal required variables
- **Clean Resource Naming**: Predictable resource names without random suffixes
- **Smart Defaults**: Works with minimal configuration, powerful when needed
- **Security-First**: No automatic security rules - explicit security configuration
- **Complete Infrastructure**: Resource Groups, VNets, Subnets, VMs, VPN Gateway
- **VNet Peering**: Automatic hub-spoke peering configuration
- **Windows Server 2025**: Latest Windows Server with password authentication
- **Flexible VM Deployment**: Deploy VMs across hub and spoke networks
- **VPN Gateway**: Site-to-site VPN connectivity with comprehensive configuration
- **Comprehensive Tagging**: Automatic tagging with creation date and metadata
- **Multi-Subscription**: Support for ALZ multi-subscription patterns
- **Backward Compatibility**: Existing configurations continue to work

## 🏃 Quick Start

### Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- Azure subscription with appropriate permissions

### Authentication

```bash
az login
az account set --subscription "your-subscription-id"
```

### Option 1: Single VNet (Original)

```bash
# Use the single VNet configuration
cp terraform.tfvars.single-vnet terraform.tfvars

# Edit terraform.tfvars with your values
# Initialize and deploy
tofu init
tofu plan
tofu apply
```

### Option 2: Hub-Spoke ALZ

```bash
# Use the ALZ hub-spoke configuration
cp terraform.tfvars.hub-spoke terraform.tfvars

# Edit terraform.tfvars with your values
# Initialize and deploy
tofu init
tofu plan
tofu apply
```

## 📋 Configuration Options

### Architecture Selection

Control your deployment architecture with the `architecture_mode` variable:

```hcl
# Single VNet (backward compatible)
architecture_mode = "single-vnet"

# Hub-Spoke ALZ
architecture_mode = "hub-spoke"
```

### Component Deployment Control

Choose which components to deploy:

```hcl
deploy_components = {
  vpn_gateway = true   # Deploy VPN Gateway
  vms         = true   # Deploy Virtual Machines
  peering     = true   # Enable VNet peering (hub-spoke only)
}
```

## 🏗️ Hub-Spoke ALZ Configuration

### Multi-Subscription Setup

```hcl
# Multi-Subscription Configuration
subscriptions = {
  hub = "52bc998c-51a4-40fa-be04-26774b4c5f0e"    # Hub/Connectivity subscription
  spoke = {
    "test-workload" = "caaf1a53-3a0a-42e4-9688-4aac8f95a2d7"    # Test workload subscription
  }
}
```

### Hub VNet (Connectivity)

```hcl
hub_vnet = {
  enabled             = true
  name               = "vnet-hub-test"
  resource_group_name = "rg-hub-test"
  cidr               = "10.1.0.0/20"
  location           = "West Europe"
  subnets            = ["GatewaySubnet", "ManagementSubnet"]
}
```

### Spoke VNets (Workloads)

```hcl
spoke_vnets = {
  "test-workload" = {
    enabled             = true
    name               = "vnet-spoke-test"
    resource_group_name = "rg-spoke-test"
    cidr               = "10.2.0.0/20"
    location           = "West Europe"
    subnets            = ["subnet-test", "subnet-app"]
    peer_to_hub        = true
    spoke_name          = "test-workload"  # Uses subscriptions.spoke["test-workload"]
  }
}
```

### VNet Peering Configuration

```hcl
# Uses ALZ-optimized defaults from generalized module
vnet_peering = {
  enabled             = true
  use_remote_gateways = false  # Override default if no VPN deployed
  # Other settings use secure defaults:
  # allow_virtual_network_access = true (default)
  # allow_forwarded_traffic = true (default) 
  # allow_gateway_transit = true (default)
}
```

## 🖥️ Virtual Machine Configuration (Generalized Module)

The VM module follows security-first principles with minimal required variables:

### Required Variables Only
```hcl
virtual_machines = {
  "test-vm-01" = {
    # REQUIRED: Where to deploy
    subnet_name         = "subnet-test"
    resource_group_name = "rg-test-vm"
    
    # OPTIONAL: Everything else has smart defaults
    spoke_name          = "test-workload"       # Deploy to specific spoke
    enable_public_ip    = true                  # Override default (false)
    os_disk_type        = "Standard_LRS"        # Override default (Premium_LRS)
    
    # SECURITY: Explicit NSG rules (no automatic rules)
    nsg_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"           # Change to your IP for security
        destination_address_prefix = "*"
      }
    ]
  }
}
```

### What You Get by Default
- **VM Size**: `Standard_B2s` (cost-effective default)
- **OS Disk**: `Premium_LRS` (performance default)
- **Public IP**: `false` (security default)
- **NSG**: Only created if `nsg_rules` are provided
- **Admin Credentials**: Uses global `admin_username` and `admin_password`
- **Clean Naming**: `test-vm-01` (no random suffixes)

### Multi-Spoke VM Deployment

```hcl
virtual_machines = {
  # Production VM in production spoke
  "prod-web-01" = {
    subnet_name         = "subnet-web"
    resource_group_name = "rg-prod-web"
    spoke_name          = "production"       # Deploy to production spoke
    vm_size             = "Standard_D2s_v3"  # Override default
    enable_public_ip    = false              # Private VM
    nsg_rules           = []                 # No NSG (subnet-level security)
  }
  
  # Management VM in hub (no spoke_name = hub deployment)
  "mgmt-vm-01" = {
    subnet_name         = "ManagementSubnet"
    resource_group_name = "rg-hub-mgmt"
    spoke_name          = null               # Deploy to hub VNet
    enable_public_ip    = true               # Management access
    nsg_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "YOUR.IP.ADDRESS/32"  # Restrict to your IP
        destination_address_prefix = "*"
      }
    ]
  }
}
```

## 🔐 VPN Configuration (Generalized Module)

The VPN module uses smart defaults and minimal required configuration:

### Required Variables Only
```hcl
vpn_configuration = {
  # REQUIRED: Basic gateway configuration
  vpn_gateway_name = "vpn-gateway-test"
  
  # OPTIONAL: Smart defaults for everything else
  vpn_gateway_sku  = "Basic"              # Override default (VpnGw1) for testing
  
  # OPTIONAL: Local Network Gateway (null = gateway-only mode)
  local_network_gateway = {
    gateway_address = "203.0.113.12"           # Your on-premises public IP
    address_space   = ["192.168.0.0/16"]       # Your on-premises networks
    # name auto-generated if not specified
  }
  
  # OPTIONAL: VPN Connection (null = no connection)
  vpn_connection = {
    shared_key = "TestSharedKey123!"  # Required if creating connection
    # name and connection_protocol auto-generated/defaulted
  }
}
```

### What You Get by Default
- **VPN Type**: `RouteBased` (modern default)
- **BGP**: `false` (disabled by default)
- **Public IP**: Auto-configured based on gateway SKU
- **Connection Protocol**: `IKEv2` (secure default)
- **Clean Naming**: `vpn-gateway-test`, `vpn-connection-test` (no random suffixes)

## 📊 Outputs

### Architecture Information

```hcl
# Current architecture mode
output "architecture_mode"

# Hub-Spoke ALZ outputs
output "hub_vnet"           # Hub VNet information
output "spoke_vnets"        # All spoke VNets information
output "vnet_peering"       # Peering status and configuration
```

### Virtual Machines

```hcl
output "virtual_machines"   # Complete VM information
output "rdp_connections"    # RDP connection strings
output "vm_private_ips"     # Private IP addresses
output "vm_public_ips"      # Public IP addresses (if enabled)
output "vm_resource_groups" # Resource group names
```

### VPN Gateway

```hcl
output "vpn_gateway_info"   # VPN Gateway details
output "vpn_summary"        # Complete VPN configuration
```

### Deployment Summary

```hcl
output "deployment_summary" # Overview of deployed resources
output "connection_guide"   # Quick connection guide
```

## 📁 Project Structure

```
.
├── modules/
│   ├── azure-networking/     # VNet and subnet management (generalized)
│   ├── azure-vm/            # Virtual machine deployment (generalized)
│   ├── azure-vpn/           # VPN Gateway and connections (generalized)
│   └── azure-vnet-peering/  # VNet peering management (generalized)
├── memory-bank/              # Project documentation
├── main.tf                   # Root configuration with conditional logic
├── variables.tf              # All configuration variables
├── outputs.tf                # Comprehensive outputs
├── terraform.tfvars          # Current test configuration
├── terraform.tfvars.single-vnet      # Single VNet example
├── terraform.tfvars.hub-spoke        # Hub-Spoke ALZ example
├── terraform.tfvars.example          # Original example
├── MODULE-GENERALIZATION-GUIDE.md    # Module design principles
└── README.md
```

## 🎯 Module Generalization Benefits

### Security-First Design
- **No automatic security rules** - Users must explicitly define what they want
- **Principle of least privilege** - Start with minimal access, add what's needed
- **Explicit over implicit** - No hidden assumptions about security requirements

### Minimal Required Input
- **VM Module**: Only `subnet_id`, `admin_username`, and `resource_group_name` required
- **VPN Module**: Only `resource_group_name`, `location`, and `gateway_subnet_id` required
- **Networking Module**: Only `vnet_name`, `resource_group_name`, and `vnet_cidr` required
- **Smart defaults for everything else** - Sensible defaults that work in most scenarios

### Maximum Flexibility
- **Every hardcoded value is configurable** - What seems fixed today may need to change tomorrow
- **Comprehensive validation** - Prevent common misconfigurations with clear error messages
- **Multiple usage patterns** - Support simple POCs to complex production deployments

### Clean Resource Naming
- **No random suffixes** - Predictable resource names like `rg-test-vm` instead of `rg-test-vm-35d3ffc4`
- **Auto-generation when needed** - Names auto-generated if not specified
- **Consistent patterns** - All modules follow the same naming conventions

## 🔧 Advanced Configuration

### Minimal VM Configuration
```hcl
# Only required variables - everything else uses smart defaults
virtual_machines = {
  "simple-vm" = {
    subnet_name         = "subnet-test"
    resource_group_name = "rg-simple"
    # Gets: Standard_B2s, Premium_LRS, no public IP, no NSG
  }
}
```

### Security-Focused VM Configuration
```hcl
virtual_machines = {
  "secure-vm" = {
    subnet_name         = "subnet-internal"
    resource_group_name = "rg-secure"
    enable_public_ip    = false              # Private only
    nsg_rules           = []                 # No NSG - subnet-level security
    os_disk_type        = "Premium_LRS"      # High performance
  }
}
```

### Gateway-Only VPN Configuration
```hcl
vpn_configuration = {
  vpn_gateway_name = "vpn-gateway-hub"
  # No local_network_gateway or vpn_connection = gateway-only mode
  # Useful for multi-site scenarios or ExpressRoute coexistence
}
```

## 🚀 Deployment Examples

### Minimal ALZ Deployment

```bash
# 1. Copy ALZ configuration
cp terraform.tfvars.hub-spoke terraform.tfvars

# 2. Edit only required values
# - Update subscription IDs
# - Configure basic networking
# - Define minimal VM requirements

# 3. Deploy
tofu init
tofu plan    # Review clean resource names
tofu apply
```

### Phased Deployment

```bash
# Phase 1: Deploy networking only
# Set deploy_components.vms = false
# Set deploy_components.vpn_gateway = false
tofu apply

# Phase 2: Add VPN Gateway
# Set deploy_components.vpn_gateway = true
tofu apply

# Phase 3: Add Virtual Machines
# Set deploy_components.vms = true
tofu apply
```

## 🏷️ Resource Tagging

All resources are automatically tagged with comprehensive metadata:

```hcl
# Automatic tags from generalized modules
tags = {
  creation_date   = "2025-01-16"
  creation_time   = "2025-01-16 14:32:00 CET"
  creation_method = "OpenTofu"
  environment     = "Test"
  project         = "Azure ALZ Multi-Subscription Test"
  tier           = "networking-hub|networking-spoke|vpn|vm"
  architecture   = "hub-spoke"
  vm_name        = "test-vm-01"      # VM-specific tags
  vm_size        = "Standard_B2s"    # VM-specific tags
  vpn_gateway_sku = "Basic"          # VPN-specific tags
}
```

## 🔒 Security Considerations

### Network Security
- **No automatic NSG rules** - Must explicitly define security rules
- **Subnet-level security by default** - VMs rely on subnet NSGs unless overridden
- **Private by default** - VMs created without public IPs unless explicitly enabled
- **Explicit security posture** - Users must consciously choose their security stance

### Hub-Spoke Security Benefits
- **Network Segmentation**: Hub-spoke provides natural network segmentation
- **Centralized Connectivity**: VPN and ExpressRoute in hub only
- **Private Workloads**: Application VMs deployed without public IPs
- **Management Access**: Dedicated management subnet with controlled access

### Security Examples

```hcl
# Secure internal VM (recommended)
"internal-vm" = {
  subnet_name         = "subnet-internal"
  resource_group_name = "rg-internal"
  enable_public_ip    = false              # Private only
  nsg_rules           = []                 # No NSG - subnet security
}

# Management VM with restricted access
"mgmt-vm" = {
  subnet_name         = "ManagementSubnet"
  resource_group_name = "rg-mgmt"
  enable_public_ip    = true               # Management access
  nsg_rules = [
    {
      name                       = "AllowRDPFromOffice"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "203.0.113.0/24"  # Office IP range
      destination_address_prefix = "*"
    }
  ]
}
```

## 🧹 Cleanup

```bash
# Destroy all resources
tofu destroy

# Note: VPN Gateway deletion takes 10-15 minutes
# VNet peering is automatically removed with VNets
# Clean resource names make it easy to identify what's being destroyed
```

## 📚 Configuration Examples

- `terraform.tfvars`: Current test configuration (hub-spoke ALZ)
- `terraform.tfvars.single-vnet`: Backward-compatible single VNet
- `terraform.tfvars.hub-spoke`: Complete ALZ hub-spoke setup
- `terraform.tfvars.example`: Original simple configuration

## 🎓 Key Improvements

### From Previous Version
1. **Removed Random Suffixes**: Clean, predictable resource names
2. **Generalized Modules**: Security-first design with minimal required variables
3. **Smart Defaults**: Works with minimal configuration
4. **Explicit Security**: No automatic security rules
5. **Comprehensive Validation**: Better error messages and configuration validation
6. **Enhanced Outputs**: More detailed connection and deployment information

### Module Design Principles
- **Security-First**: No automatic security rules - explicit security configuration
- **Minimal Required Input**: Only 1-3 required variables per module
- **Maximum Flexibility**: Every hardcoded value is configurable
- **Progressive Complexity**: Simple by default, powerful when needed
- **Comprehensive Validation**: Prevent common misconfigurations

## 🤝 Contributing

This project follows the principles outlined in `MODULE-GENERALIZATION-GUIDE.md`. For additional features:
- Azure Firewall integration
- ExpressRoute support
- Multiple regions
- Advanced monitoring
- Backup configuration

## 📄 License

This project is provided as-is for educational and production use.
