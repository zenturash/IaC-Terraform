# Azure Landing Zone (ALZ) OpenTofu Module

A flexible OpenTofu module for deploying Azure infrastructure with support for both single VNet and Azure Landing Zone (ALZ) hub-spoke architectures. Perfect for POCs, development environments, and production ALZ implementations.

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

## 🚀 Features

- **Dual Architecture Support**: Choose between single-vnet or hub-spoke ALZ
- **Variable-Controlled Deployment**: Control exactly what gets deployed
- **Complete Infrastructure**: Resource Groups, VNets, Subnets, VMs, VPN Gateway
- **VNet Peering**: Automatic hub-spoke peering configuration
- **Windows Server 2025**: Latest Windows Server with password authentication
- **Flexible VM Deployment**: Deploy VMs in appropriate network tiers
- **VPN Gateway**: Site-to-site VPN connectivity
- **Comprehensive Tagging**: Automatic tagging with creation date and metadata
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

### Hub VNet (Connectivity)

```hcl
hub_vnet = {
  enabled             = true
  name               = "vnet-hub-connectivity"
  resource_group_name = "rg-hub-connectivity"
  cidr               = "10.1.0.0/20"
  location           = "West Europe"
  subnets            = ["GatewaySubnet", "AzureFirewallSubnet", "ManagementSubnet"]
}
```

### Spoke VNets (Workloads)

```hcl
spoke_vnets = {
  "workload" = {
    enabled             = true
    name               = "vnet-spoke-workload"
    resource_group_name = "rg-spoke-workload"
    cidr               = "10.2.0.0/20"
    location           = "West Europe"
    subnets            = ["subnet-app", "subnet-data", "subnet-mgmt"]
    peer_to_hub        = true
    spoke_name          = "workload"  # Uses subscriptions.spoke["workload"]
  }
  "dmz" = {
    enabled             = true
    name               = "vnet-spoke-dmz"
    resource_group_name = "rg-spoke-dmz"
    cidr               = "10.3.0.0/20"
    location           = "West Europe"
    subnets            = ["subnet-web", "subnet-lb"]
    peer_to_hub        = true
    spoke_name          = "dmz"  # Uses subscriptions.spoke["dmz"]
  }
}
```

### VNet Peering Configuration

```hcl
vnet_peering = {
  enabled                    = true
  allow_virtual_network_access = true
  allow_forwarded_traffic    = true
  allow_gateway_transit      = true   # Hub provides gateway
  use_remote_gateways        = true   # Spokes use hub gateway
}
```

## 🖥️ Virtual Machine Configuration

VMs can be deployed across multiple spokes using the `spoke_name` parameter:

```hcl
virtual_machines = {
  # Production VM in production spoke
  "prod-web-01" = {
    vm_size             = "Standard_D2s_v3"
    subnet_name         = "subnet-web"
    resource_group_name = "rg-prod-web"
    enable_public_ip    = false
    os_disk_type        = "Premium_LRS"
    spoke_name          = "production"       # Deploy to production spoke
  }
  
  # Development VM in development spoke
  "dev-app-01" = {
    vm_size             = "Standard_B2s"
    subnet_name         = "subnet-dev-app"
    resource_group_name = "rg-dev-app"
    enable_public_ip    = false
    os_disk_type        = "Standard_LRS"
    spoke_name          = "development"      # Deploy to development spoke
  }
  
  # Management VM in hub (no spoke_name = hub deployment)
  "mgmt-vm-01" = {
    vm_size             = "Standard_B2s"
    subnet_name         = "ManagementSubnet"
    resource_group_name = "rg-hub-mgmt"
    enable_public_ip    = true               # Management access
    os_disk_type        = "Premium_LRS"
    spoke_name          = null               # Deploy to hub VNet
    nsg_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "YOUR.IP.ADDRESS/32"
        destination_address_prefix = "*"
      }
    ]
  }
}
```

### Multi-Subscription Configuration

Configure subscriptions for hub and spokes:

```hcl
subscriptions = {
  hub = "hub-subscription-id"              # Hub/Connectivity subscription
  spoke = {
    "production"  = "prod-subscription-id"  # Production workload subscription
    "development" = "dev-subscription-id"   # Development subscription
    "dmz"         = "dmz-subscription-id"   # DMZ/Security subscription
  }
}
```

## 🔐 VPN Configuration

VPN Gateway is deployed in the hub (ALZ) or single VNet:

```hcl
vpn_configuration = {
  vpn_gateway_name = "vpn-gateway-hub"
  vpn_gateway_sku  = "VpnGw1"              # Standard SKU
  vpn_type         = "RouteBased"
  enable_bgp       = false
  
  local_network_gateway = {
    name            = "local-gateway-office"
    gateway_address = "YOUR.PUBLIC.IP"      # Your on-premises public IP
    address_space   = ["192.168.0.0/16"]   # Your on-premises networks
  }
  
  vpn_connection = {
    name                = "vpn-connection-hub"
    shared_key          = "YourSecureSharedKey123!"
    connection_protocol = "IKEv2"
  }
}
```

## 📊 Outputs

### Architecture Information

```hcl
# Current architecture mode
output "architecture_mode"

# Single VNet outputs (backward compatibility)
output "virtual_network_name"
output "subnet_ids"

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
│   ├── azure-networking/   # VNet and subnet management
│   ├── azure-vm/          # Virtual machine deployment
│   ├── azure-vpn/         # VPN Gateway and connections
│   └── azure-vnet-peering/ # VNet peering management
├── memory-bank/            # Project documentation
├── main.tf                 # Root configuration with conditional logic
├── variables.tf            # All configuration variables
├── outputs.tf              # Comprehensive outputs
├── terraform.tfvars.single-vnet    # Single VNet example
├── terraform.tfvars.hub-spoke      # Hub-Spoke ALZ example
├── terraform.tfvars.example        # Original example
└── README.md
```

## 🎯 Use Cases

### Single VNet Mode
- **Development environments**
- **Simple POCs**
- **Small workloads**
- **Backward compatibility**

### Hub-Spoke ALZ Mode
- **Production environments**
- **Multi-tier applications**
- **Centralized connectivity**
- **Compliance requirements**
- **Scalable architecture**

## 🔧 Advanced Configuration

### Multiple Spoke VNets

```hcl
spoke_vnets = {
  "production" = {
    enabled = true
    name = "vnet-spoke-prod"
    cidr = "10.2.0.0/20"
    subnets = ["subnet-web", "subnet-app", "subnet-db"]
    peer_to_hub = true
  }
  "development" = {
    enabled = true
    name = "vnet-spoke-dev"
    cidr = "10.3.0.0/20"
    subnets = ["subnet-dev-app", "subnet-dev-db"]
    peer_to_hub = true
  }
  "dmz" = {
    enabled = false  # Can be enabled later
    name = "vnet-spoke-dmz"
    cidr = "10.4.0.0/20"
    subnets = ["subnet-public", "subnet-waf"]
    peer_to_hub = true
  }
}
```

### Conditional Deployments

```hcl
# Deploy only networking (no VMs or VPN)
deploy_components = {
  vpn_gateway = false
  vms         = false
  peering     = true
}

# Deploy everything
deploy_components = {
  vpn_gateway = true
  vms         = true
  peering     = true
}
```

## 🚀 Deployment Examples

### Basic ALZ Deployment

```bash
# 1. Copy ALZ configuration
cp terraform.tfvars.hub-spoke terraform.tfvars

# 2. Edit configuration
# - Update IP addresses
# - Configure VPN settings
# - Define VM requirements

# 3. Deploy
tofu init
tofu plan
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

All resources are automatically tagged:

```hcl
tags = {
  creation_date   = "2025-01-07"
  creation_method = "OpenTofu"
  environment     = "POC"
  project         = "Azure ALZ POC"
  tier           = "networking-hub|networking-spoke|vpn|vm"
  architecture   = "single-vnet|hub-spoke"
}
```

## 🔒 Security Considerations

- **Network Segmentation**: Hub-spoke provides natural network segmentation
- **Centralized Connectivity**: VPN and ExpressRoute in hub only
- **Private VMs**: Application VMs can be deployed without public IPs
- **Management Access**: Dedicated management subnet with controlled access
- **NSG Rules**: Configurable Network Security Group rules per VM

## 🧹 Cleanup

```bash
# Destroy all resources
tofu destroy

# Note: VPN Gateway deletion takes 10-15 minutes
# VNet peering is automatically removed with VNets
```

## 📚 Examples

- `terraform.tfvars.single-vnet`: Backward-compatible single VNet
- `terraform.tfvars.hub-spoke`: Complete ALZ hub-spoke setup
- `terraform.tfvars.example`: Original simple configuration

## 🤝 Contributing

This project supports both simple POCs and production ALZ implementations. For additional features:
- Azure Firewall integration
- ExpressRoute support
- Multiple regions
- Advanced monitoring
- Backup configuration

## 📄 License

This project is provided as-is for educational and production use.
