# Azure VM OpenTofu Module

A highly flexible and secure OpenTofu module for deploying Azure Windows Virtual Machines with comprehensive configuration options and sensible defaults.

## 🚀 Key Features

✅ **Minimal Required Input** - Only `subnet_id` and `resource_group_name` required, everything else has smart defaults  
✅ **Security-First Approach** - No automatic NSG rules, users must explicitly define security  
✅ **Maximum Flexibility** - Every hardcoded value is now configurable with defaults  
✅ **Auto-Generation** - VM names, passwords, and resource names auto-generated for uniqueness  
✅ **Multiple Instance Support** - Deploy multiple VMs without conflicts  
✅ **NSG Independence** - NSG creation is independent of public IP configuration  
✅ **Comprehensive Outputs** - Detailed outputs including connection information  

## 🔧 Requirements

- OpenTofu >= 1.0
- Azure Provider >= 3.0
- Random Provider >= 3.1

## 📋 Quick Start

### Minimal Usage (Only required variables)

```hcl
module "simple_vm" {
  source = "./modules/azure-vm"
  
  subnet_id           = "/subscriptions/your-sub/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/subnet-app"
  resource_group_name = "rg-vm-prod"
}
```

**What you get:**
- VM with auto-generated name (e.g., `vm-a1b2c3d4`)
- Auto-generated secure password (output as sensitive)
- Windows Server 2025 Datacenter Azure Edition
- Standard_B2s VM size
- Premium_LRS OS disk
- No public IP (private only)
- No NSG (uses subnet-level security)
- Resource group: `rg-vm-prod-a1b2c3d4` (with random suffix)

## 🛡️ Security Examples

### 1. VM without NSG (Recommended for Internal VMs)

```hcl
# Most common pattern - no NSG, relies on subnet-level security
module "internal_vm" {
  source = "./modules/azure-vm"
  
  subnet_id = var.internal_subnet_id
  vm_name   = "app-server-01"
  # create_nsg = false (this is the default)
}
```

**Security posture:**
- No NSG created at VM level
- Relies entirely on subnet-level Network Security Groups
- Most secure and recommended approach for internal VMs
- Simpler management - security rules managed at subnet level

### 2. Public VM without NSG (Uses Subnet Security)

```hcl
# Public VM that relies on subnet NSG for security
module "public_vm_no_nsg" {
  source = "./modules/azure-vm"
  
  subnet_id        = var.public_subnet_id
  vm_name          = "public-server-01"
  enable_public_ip = true
  # create_nsg = false (default - no VM-level NSG)
}
```

**Security posture:**
- VM has public IP but no VM-level NSG
- Security controlled by subnet-level NSG rules
- Good for scenarios where subnet already has appropriate rules
- Reduces NSG sprawl and management overhead

### Public VM with Explicit NSG Rules

```hcl
module "web_server" {
  source = "./modules/azure-vm"
  
  subnet_id        = var.web_subnet_id
  vm_name          = "web-server-01"
  enable_public_ip = true
  create_nsg       = true
  
  # Users must explicitly define ALL security rules
  nsg_rules = [
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
      name                       = "AllowRDPFromOffice"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "203.0.113.0/24"  # Your office IP
      destination_address_prefix = "*"
    }
  ]
}
```

### Multiple VMs (No Conflicts)

```hcl
# Web tier
module "web_vm_01" {
  source = "./modules/azure-vm"
  
  subnet_id        = var.web_subnet_id
  vm_name          = "web-01"
  enable_public_ip = true
  create_nsg       = true
  vm_size          = "Standard_D2s_v3"
  
  nsg_rules = [
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
    }
  ]
}

# App tier
module "app_vm_01" {
  source = "./modules/azure-vm"
  
  subnet_id  = var.app_subnet_id
  vm_name    = "app-01"
  create_nsg = true
  vm_size    = "Standard_D4s_v3"
  
  nsg_rules = [
    {
      name                       = "AllowAppPort"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "10.0.1.0/24"  # Web subnet
      destination_address_prefix = "*"
    }
  ]
}
```

## 📝 Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `subnet_id` | ID of the subnet where the VM will be deployed | `string` |
| `resource_group_name` | Name for the resource group | `string` |

### Core Configuration (Optional with Defaults)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vm_name` | Name of the virtual machine (auto-generated if null) | `string` | `null` |
| `vm_size` | Size of the virtual machine | `string` | `"Standard_B2s"` |
| `admin_username` | Administrator username | `string` | `"azureuser"` |
| `admin_password` | Administrator password (auto-generated if null) | `string` | `null` |
| `location` | Azure region | `string` | `"West Europe"` |

### Network Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_public_ip` | Whether to create a public IP | `bool` | `false` |
| `public_ip_allocation_method` | Public IP allocation method | `string` | `"Static"` |
| `public_ip_sku` | Public IP SKU | `string` | `"Standard"` |
| `private_ip_allocation` | Private IP allocation method | `string` | `"Dynamic"` |
| `private_ip_address` | Static private IP (when allocation is Static) | `string` | `null` |

### Security Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_nsg` | Whether to create a Network Security Group | `bool` | `false` |
| `nsg_rules` | List of NSG rules to create | `list(object)` | `[]` |

### Storage Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `os_disk_type` | Storage account type for OS disk | `string` | `"Premium_LRS"` |
| `os_disk_caching` | OS disk caching type | `string` | `"ReadWrite"` |
| `os_disk_size_gb` | OS disk size in GB | `number` | `null` |

### VM Image Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `image_publisher` | VM image publisher | `string` | `"MicrosoftWindowsServer"` |
| `image_offer` | VM image offer | `string` | `"WindowsServer"` |
| `image_sku` | VM image SKU | `string` | `"2025-datacenter-azure-edition"` |
| `image_version` | VM image version | `string` | `"latest"` |

### Resource Naming

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `use_random_suffix` | Add random suffix for uniqueness | `bool` | `true` |
| `public_ip_name_prefix` | Public IP name prefix | `string` | `"pip"` |
| `nsg_name_prefix` | NSG name prefix | `string` | `"nsg"` |
| `nic_name_prefix` | NIC name prefix | `string` | `"nic"` |

### Advanced Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `patch_mode` | VM patch mode | `string` | `"AutomaticByPlatform"` |
| `timezone` | VM timezone | `string` | `"UTC"` |
| `zone` | Availability zone | `string` | `null` |
| `identity_type` | Managed identity type | `string` | `"SystemAssigned"` |
| `boot_diagnostics_enabled` | Enable boot diagnostics | `bool` | `true` |

## 📤 Outputs

### Core VM Information

| Name | Description |
|------|-------------|
| `vm_id` | Virtual machine ID |
| `vm_name` | Virtual machine name |
| `vm_size` | Virtual machine size |
| `admin_username` | Administrator username |
| `admin_password` | Administrator password (sensitive) |
| `password_auto_generated` | Whether password was auto-generated |

### Network Information

| Name | Description |
|------|-------------|
| `private_ip_address` | Private IP address |
| `public_ip_address` | Public IP address (if enabled) |
| `network_interface_id` | Network interface ID |
| `network_security_group_id` | NSG ID (if created) |

### Connection Information

| Name | Description |
|------|-------------|
| `rdp_connection_string` | RDP connection command |
| `connection_guide` | Complete connection guide with security notes |
| `vm_summary` | Comprehensive VM summary |

## 🔒 Security Best Practices

### 1. NSG Rules Are Explicit
- **No automatic rules** - Users must define exactly what they want
- **No hidden RDP rules** - If you want RDP access, explicitly create the rule
- **Principle of least privilege** - Start with no access, add what's needed

### 2. Default Security Posture
- **No public IP by default** - VMs are private unless explicitly configured
- **No NSG by default** - Relies on subnet-level security
- **Secure password generation** - Auto-generated passwords are complex and unique

### 3. Recommended Patterns
- **Internal VMs**: No NSG, rely on subnet security
- **Public VMs**: Create NSG with explicit rules for required access
- **Jump servers**: NSG with RDP restricted to admin IP ranges
- **Web servers**: NSG with HTTP/HTTPS and restricted management access

## 🎯 Use Cases

### Development Environment
```hcl
module "dev_vm" {
  source = "./modules/azure-vm"
  
  subnet_id        = var.dev_subnet_id
  vm_name          = "dev-workstation"
  enable_public_ip = true
  vm_size          = "Standard_D4s_v3"
  create_nsg       = true
  
  nsg_rules = [
    {
      name                       = "AllowRDPFromHome"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "YOUR.HOME.IP/32"
      destination_address_prefix = "*"
    }
  ]
}
```

### Production Web Server
```hcl
module "prod_web" {
  source = "./modules/azure-vm"
  
  subnet_id        = var.web_subnet_id
  vm_name          = "prod-web-01"
  enable_public_ip = true
  vm_size          = "Standard_D8s_v3"
  os_disk_type     = "Premium_LRS"
  create_nsg       = true
  
  nsg_rules = [
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
}
```

### Internal Database Server
```hcl
module "db_server" {
  source = "./modules/azure-vm"
  
  subnet_id    = var.db_subnet_id
  vm_name      = "db-server-01"
  vm_size      = "Standard_E8s_v3"
  os_disk_type = "Premium_LRS"
  create_nsg   = true
  
  nsg_rules = [
    {
      name                       = "AllowSQLFromApp"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.2.0/24"  # App subnet
      destination_address_prefix = "*"
    }
  ]
}
```

## 🔄 Migration from Previous Version

If you're upgrading from the previous version:

1. **NSG behavior changed**: NSG is now optional and independent of public IP
2. **No automatic RDP rules**: You must explicitly define RDP rules if needed
3. **More variables available**: Many previously hardcoded values are now configurable
4. **Better defaults**: Sensible defaults for most scenarios

### Example Migration

**Old approach:**
```hcl
module "vm" {
  source = "./modules/azure-vm"
  
  vm_name        = "my-vm"
  admin_username = "admin"
  admin_password = "MyPassword123!"
  subnet_id      = var.subnet_id
  enable_public_ip = true
}
```

**New approach (equivalent):**
```hcl
module "vm" {
  source = "./modules/azure-vm"
  
  vm_name          = "my-vm"
  admin_username   = "admin"
  admin_password   = "MyPassword123!"
  subnet_id        = var.subnet_id
  enable_public_ip = true
  create_nsg       = true  # Now explicit
  
  # Must explicitly define RDP rule if needed
  nsg_rules = [
    {
      name                       = "AllowRDP"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "YOUR.IP.RANGE/24"
      destination_address_prefix = "*"
    }
  ]
}
```

## 📚 Additional Resources

- [Azure VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)
- [Azure NSG Rules](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [OpenTofu Documentation](https://opentofu.org/docs/)

## 🤝 Contributing

This module follows security-first principles. When contributing:
- No automatic security rules
- Explicit configuration over implicit behavior
- Comprehensive validation and documentation
- Backward compatibility where possible
