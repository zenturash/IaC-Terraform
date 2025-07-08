# Azure VM Module

This module creates Azure Windows Virtual Machines with comprehensive networking, security, and storage configuration options.

## Features

- **Windows Server 2025**: Latest Windows Server with Azure Edition
- **Flexible VM Sizing**: Support for various Azure VM sizes with validation
- **Network Security**: Optional Network Security Groups with custom rules
- **Public IP Support**: Conditional public IP assignment
- **Storage Options**: Multiple storage account types for OS disks
- **Password Authentication**: Secure password-based authentication
- **Automatic Patching**: AutomaticByPlatform patch mode
- **Resource Group Management**: Creates dedicated resource group per VM
- **Comprehensive Outputs**: Complete VM and networking information

## Usage

### Basic VM (Private)

```hcl
module "vm" {
  source = "./modules/azure-vm"

  vm_name        = "vm-web-01"
  admin_username = "azureuser"
  admin_password = "ComplexPassword123!"
  subnet_id      = "/subscriptions/.../subnets/subnet-web"
  
  vm_size             = "Standard_B2s"
  resource_group_name = "rg-web-servers"
  
  tags = {
    environment = "production"
    tier        = "web"
  }
}
```

### VM with Public IP and NSG

```hcl
module "vm_public" {
  source = "./modules/azure-vm"

  vm_name        = "vm-mgmt-01"
  admin_username = "azureuser"
  admin_password = "ComplexPassword123!"
  subnet_id      = "/subscriptions/.../subnets/subnet-mgmt"
  
  vm_size          = "Standard_D2s_v3"
  enable_public_ip = true
  
  resource_group_name = "rg-management"
  
  nsg_rules = [
    {
      name                       = "AllowRDP"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "203.0.113.0/24"  # Your office IP range
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPS"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = {
    environment = "production"
    tier        = "management"
    public_access = "true"
  }
}
```

### High-Performance VM

```hcl
module "vm_app" {
  source = "./modules/azure-vm"

  vm_name        = "vm-app-01"
  admin_username = "azureuser"
  admin_password = "ComplexPassword123!"
  subnet_id      = "/subscriptions/.../subnets/subnet-app"
  
  vm_size      = "Standard_D4s_v3"
  os_disk_type = "Premium_LRS"  # High-performance storage
  
  resource_group_name = "rg-application"
  
  tags = {
    environment = "production"
    tier        = "application"
    performance = "high"
  }
}
```

## VM Sizes

The module supports and validates the following Azure VM sizes:

### Burstable (B-series)
- `Standard_B1s` - 1 vCPU, 1 GB RAM (Basic workloads)
- `Standard_B2s` - 2 vCPU, 4 GB RAM (Light workloads)
- `Standard_B4ms` - 4 vCPU, 16 GB RAM (Medium workloads)

### General Purpose (D-series)
- `Standard_D2s_v3` - 2 vCPU, 8 GB RAM
- `Standard_D4s_v3` - 4 vCPU, 16 GB RAM
- `Standard_D8s_v3` - 8 vCPU, 32 GB RAM

### Memory Optimized (E-series)
- `Standard_E2s_v3` - 2 vCPU, 16 GB RAM
- `Standard_E4s_v3` - 4 vCPU, 32 GB RAM
- `Standard_E8s_v3` - 8 vCPU, 64 GB RAM

### Compute Optimized (F-series)
- `Standard_F2s_v2` - 2 vCPU, 4 GB RAM
- `Standard_F4s_v2` - 4 vCPU, 8 GB RAM
- `Standard_F8s_v2` - 8 vCPU, 16 GB RAM

## Storage Options

### OS Disk Types
- `Standard_LRS` - Standard locally redundant storage (cost-effective)
- `StandardSSD_LRS` - Standard SSD locally redundant storage (balanced)
- `Premium_LRS` - Premium SSD locally redundant storage (high performance)
- `UltraSSD_LRS` - Ultra SSD locally redundant storage (ultra-high performance)

## Network Security Groups

### NSG Rule Structure

```hcl
nsg_rules = [
  {
    name                       = "RuleName"
    priority                   = 1000                    # 100-4096
    direction                  = "Inbound"               # Inbound/Outbound
    access                     = "Allow"                 # Allow/Deny
    protocol                   = "Tcp"                   # Tcp/Udp/Icmp/*
    source_port_range          = "*"                     # Port or *
    destination_port_range     = "3389"                  # Port or *
    source_address_prefix      = "10.0.0.0/24"          # CIDR or *
    destination_address_prefix = "*"                     # CIDR or *
  }
]
```

### Common NSG Rules

#### RDP Access
```hcl
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
```

#### HTTP/HTTPS Access
```hcl
{
  name                       = "AllowHTTP"
  priority                   = 1100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vm_name | Name of the virtual machine | `string` | n/a | yes |
| admin_username | Administrator username for the virtual machine | `string` | n/a | yes |
| admin_password | Administrator password for the virtual machine | `string` | n/a | yes |
| subnet_id | ID of the subnet where the VM will be deployed | `string` | n/a | yes |
| vm_size | Size of the virtual machine | `string` | `"Standard_B2s"` | no |
| location | Azure region where resources will be created | `string` | `"West Europe"` | no |
| resource_group_name | Base name for the resource group | `string` | `"rg-vm-poc"` | no |
| enable_public_ip | Whether to create and assign a public IP to the VM | `bool` | `false` | no |
| os_disk_type | Storage account type for the OS disk | `string` | `"Premium_LRS"` | no |
| nsg_rules | List of NSG rules to create when public IP is enabled | `list(object)` | `[]` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Name of the created resource group |
| resource_group_id | ID of the created resource group |
| location | Azure region where resources were created |
| vm_name | Name of the virtual machine |
| vm_id | ID of the virtual machine |
| vm_size | Size of the virtual machine |
| private_ip_address | Private IP address of the virtual machine |
| public_ip_address | Public IP address of the virtual machine (if enabled) |
| network_interface_id | ID of the network interface |
| rdp_connection_string | RDP connection string (if public IP is enabled) |
| admin_username | Administrator username for the virtual machine |
| tags | Tags applied to the VM |
| nsg_id | ID of the Network Security Group (if created) |
| nsg_name | Name of the Network Security Group (if created) |
| nsg_rules | List of NSG rules applied |

## Examples

### Web Server VM

```hcl
module "web_server" {
  source = "./modules/azure-vm"

  vm_name        = "vm-web-01"
  admin_username = "webadmin"
  admin_password = "WebServer123!"
  subnet_id      = module.networking.subnet_ids["subnet-web"]
  
  vm_size             = "Standard_D2s_v3"
  resource_group_name = "rg-web-servers"
  enable_public_ip    = true
  
  nsg_rules = [
    {
      name                       = "AllowHTTP"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPS"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = {
    environment = "production"
    tier        = "web"
    role        = "webserver"
  }
}
```

### Database Server VM

```hcl
module "database_server" {
  source = "./modules/azure-vm"

  vm_name        = "vm-db-01"
  admin_username = "dbadmin"
  admin_password = "DatabaseServer123!"
  subnet_id      = module.networking.subnet_ids["subnet-db"]
  
  vm_size      = "Standard_E4s_v3"  # Memory optimized
  os_disk_type = "Premium_LRS"      # High performance storage
  
  resource_group_name = "rg-database"
  enable_public_ip    = false       # Private database server
  
  tags = {
    environment = "production"
    tier        = "database"
    role        = "sqlserver"
    backup      = "required"
  }
}
```

### Development VM

```hcl
module "dev_vm" {
  source = "./modules/azure-vm"

  vm_name        = "vm-dev-01"
  admin_username = "developer"
  admin_password = "DevEnvironment123!"
  subnet_id      = module.networking.subnet_ids["subnet-dev"]
  
  vm_size      = "Standard_B4ms"    # Burstable for development
  os_disk_type = "StandardSSD_LRS"  # Balanced performance/cost
  
  resource_group_name = "rg-development"
  enable_public_ip    = true
  
  nsg_rules = [
    {
      name                       = "AllowRDP"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "203.0.113.0/24"  # Office network
      destination_address_prefix = "*"
    }
  ]
  
  tags = {
    environment = "development"
    tier        = "development"
    auto_shutdown = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |
| random | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Resources

- `azurerm_resource_group.main`
- `azurerm_public_ip.main` (conditional)
- `azurerm_network_security_group.main` (conditional)
- `azurerm_network_security_rule.rules` (multiple, conditional)
- `azurerm_subnet_network_security_group_association.main` (conditional)
- `azurerm_network_interface.main`
- `azurerm_windows_virtual_machine.main`

## Security Considerations

- **Password Complexity**: Ensure admin passwords meet Azure complexity requirements (12-123 characters)
- **NSG Rules**: Only open necessary ports and restrict source IP ranges
- **Public IP**: Only enable public IP when required for external access
- **Patch Management**: AutomaticByPlatform patch mode is enabled by default
- **Disk Encryption**: Consider enabling Azure Disk Encryption for sensitive workloads

## Cost Optimization

- **VM Sizing**: Start with smaller sizes and scale up as needed
- **Storage**: Use Standard_LRS for development, Premium_LRS for production
- **Public IPs**: Only assign when necessary (additional cost)
- **Auto-shutdown**: Implement auto-shutdown for development VMs
- **Reserved Instances**: Consider RIs for long-running production workloads

## Troubleshooting

### Common Issues

1. **VM Size Not Available**: Check region availability for specific VM sizes
2. **Subnet Full**: Ensure subnet has available IP addresses
3. **NSG Conflicts**: Verify NSG rule priorities don't conflict
4. **Password Policy**: Ensure password meets Azure complexity requirements
5. **Quota Limits**: Check subscription quotas for VM cores and public IPs
