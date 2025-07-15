# Azure VM OpenTofu Module

A highly flexible and secure OpenTofu module for deploying both **Windows and Linux** Azure Virtual Machines with comprehensive configuration options, explicit authentication requirements, and configurable defaults.

## 🚀 Key Features

✅ **Dual OS Support** - Deploy both Windows and Linux VMs with a single module  
✅ **Security-First Authentication** - Explicit credentials required, no auto-generation  
✅ **Minimal Required Input** - Only `subnet_id`, `resource_group_name`, `admin_username` required  
✅ **Flexible Authentication** - SSH keys, passwords, or both for Linux VMs  
✅ **Configurable Image Defaults** - Easily customize OS images for your organization  
✅ **Maximum Flexibility** - Every value is configurable with sensible defaults  
✅ **Multiple Instance Support** - Deploy multiple VMs without conflicts  
✅ **NSG Independence** - NSG creation is independent of public IP configuration  
✅ **Comprehensive Outputs** - OS-aware connection information and detailed outputs  

## 🔧 Requirements

- OpenTofu >= 1.0
- Azure Provider >= 3.0
- Random Provider >= 3.1

## 📋 Quick Start

### Windows VM (Minimal Usage)

```hcl
module "windows_vm" {
  source = "./modules/azure-vm"
  
  subnet_id           = "/subscriptions/your-sub/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/subnet-app"
  resource_group_name = "rg-vm-windows"
  admin_username      = "winadmin"
  admin_password      = "SecurePassword123!"
  # os_type = "Windows" (default)
}
```

### Linux VM with SSH Key

```hcl
module "linux_vm" {
  source = "./modules/azure-vm"
  
  subnet_id           = "/subscriptions/your-sub/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/subnet-app"
  resource_group_name = "rg-vm-linux"
  os_type             = "Linux"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  disable_password_authentication = true
}
```

### Linux VM with Password

```hcl
module "linux_password_vm" {
  source = "./modules/azure-vm"
  
  subnet_id           = "/subscriptions/your-sub/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/subnet-app"
  resource_group_name = "rg-vm-linux-pwd"
  os_type             = "Linux"
  admin_username      = "azureuser"
  admin_password      = "SecureLinuxPassword123!"
  disable_password_authentication = false
}
```

## 🖥️ Operating System Support

### Windows VMs
- **Default Image**: Windows Server 2025 Datacenter Azure Edition
- **Authentication**: Username + Password (both required)
- **Connection**: RDP (port 3389)
- **Features**: Patch management, hotpatching, timezone configuration

### Linux VMs  
- **Default Image**: Ubuntu 22.04 LTS Gen2
- **Authentication Options**:
  - SSH Key Only (recommended)
  - Password Only
  - SSH Key + Password (hybrid)
- **Connection**: SSH (port 22)
- **Features**: SSH key management, password authentication control

## 🔐 Authentication Examples

### Windows VM Authentication
```hcl
module "windows_server" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-windows-server"
  admin_username      = "winadmin"      # Required
  admin_password      = "SecurePass123!" # Required
  # os_type = "Windows" (default)
}
```

### Linux SSH Key Authentication (Recommended)
```hcl
module "linux_ssh" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-linux-ssh"
  os_type             = "Linux"
  admin_username      = "azureuser"                    # Required
  ssh_public_key      = file("~/.ssh/id_rsa.pub")     # Required
  disable_password_authentication = true              # SSH only
}
```

### Linux Password Authentication
```hcl
module "linux_password" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-linux-password"
  os_type             = "Linux"
  admin_username      = "azureuser"                    # Required
  admin_password      = "SecureLinuxPass123!"         # Required
  disable_password_authentication = false             # Allow password
}
```

### Linux Hybrid Authentication (SSH + Password)
```hcl
module "linux_hybrid" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-linux-hybrid"
  os_type             = "Linux"
  admin_username      = "azureuser"                    # Required
  ssh_public_key      = file("~/.ssh/id_rsa.pub")     # SSH access
  admin_password      = "SecureLinuxPass123!"         # Password access
  disable_password_authentication = false             # Allow both
}
```

## 🎨 Image Customization

### Using Default Images
```hcl
# Windows: Uses Windows Server 2025 Datacenter Azure Edition
module "windows_default" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-windows"
  admin_username      = "winadmin"
  admin_password      = "SecurePass123!"
}

# Linux: Uses Ubuntu 22.04 LTS Gen2
module "linux_default" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-linux"
  os_type             = "Linux"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
}
```

### Customizing Individual Image Components
```hcl
module "custom_linux" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-custom-linux"
  os_type             = "Linux"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  
  # Override individual image components
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "9-lvm-gen2"
}
```

### Organizational Image Defaults
```hcl
module "org_standard_windows" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-org-windows"
  admin_username      = "winadmin"
  admin_password      = "SecurePass123!"
  
  # Override organizational Windows defaults
  windows_image_defaults = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"  # Use 2022 instead of 2025
  }
}

module "org_standard_linux" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-org-linux"
  os_type             = "Linux"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  
  # Override organizational Linux defaults
  linux_image_defaults = {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"  # Use RHEL instead of Ubuntu
  }
}
```

## 🛡️ Security Examples

### 1. Internal VMs (No NSG - Recommended)

```hcl
# Windows internal server
module "internal_windows" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.internal_subnet_id
  resource_group_name = "rg-internal-windows"
  vm_name             = "app-server-01"
  admin_username      = "winadmin"
  admin_password      = "SecurePass123!"
  # create_nsg = false (default - uses subnet-level security)
}

# Linux internal server
module "internal_linux" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.internal_subnet_id
  resource_group_name = "rg-internal-linux"
  os_type             = "Linux"
  vm_name             = "api-server-01"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  # create_nsg = false (default - uses subnet-level security)
}
```

### 2. Public VMs with Explicit Security Rules

```hcl
# Windows web server with RDP access
module "windows_web" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.web_subnet_id
  resource_group_name = "rg-windows-web"
  vm_name             = "web-server-01"
  admin_username      = "winadmin"
  admin_password      = "SecurePass123!"
  enable_public_ip    = true
  create_nsg          = true
  
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

# Linux web server with SSH access
module "linux_web" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.web_subnet_id
  resource_group_name = "rg-linux-web"
  os_type             = "Linux"
  vm_name             = "nginx-server-01"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  enable_public_ip    = true
  create_nsg          = true
  
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
      name                       = "AllowSSHFromOffice"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "203.0.113.0/24"  # Your office IP
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
| `admin_username` | Administrator username for the virtual machine | `string` |

### Core Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `os_type` | Operating system type (Windows or Linux) | `string` | `"Windows"` |
| `vm_name` | Name of the virtual machine (auto-generated if null) | `string` | `null` |
| `vm_size` | Size of the virtual machine | `string` | `"Standard_B2s"` |
| `admin_password` | Administrator password (required for Windows, optional for Linux) | `string` | `null` |
| `location` | Azure region | `string` | `"West Europe"` |

### Linux Authentication

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ssh_public_key` | SSH public key for Linux VM authentication | `string` | `null` |
| `disable_password_authentication` | Disable password authentication for Linux VMs | `bool` | `false` |

### Image Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `image_publisher` | VM image publisher (null = use OS defaults) | `string` | `null` |
| `image_offer` | VM image offer (null = use OS defaults) | `string` | `null` |
| `image_sku` | VM image SKU (null = use OS defaults) | `string` | `null` |
| `image_version` | VM image version | `string` | `"latest"` |

### OS-Specific Image Defaults

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `windows_image_defaults` | Default Windows image configuration | `object` | Windows Server 2025 |
| `linux_image_defaults` | Default Linux image configuration | `object` | Ubuntu 22.04 LTS |

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

### Windows-Specific Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `patch_mode` | VM patch mode | `string` | `"AutomaticByPlatform"` |
| `hotpatching_enabled` | Enable hotpatching | `bool` | `false` |
| `timezone` | VM timezone | `string` | `"UTC"` |
| `enable_automatic_updates` | Enable automatic updates | `bool` | `true` |

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
| `os_type` | Operating system type |
| `admin_username` | Administrator username |
| `admin_password` | Administrator password (sensitive) |
| `password_provided` | Whether password was provided |

### Authentication Information

| Name | Description |
|------|-------------|
| `authentication_method` | Authentication method used |
| `ssh_public_key_provided` | Whether SSH key was provided (Linux only) |

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
| `rdp_connection_string` | RDP connection command (Windows) |
| `ssh_connection_string` | SSH connection command (Linux) |
| `connection_command` | OS-appropriate connection command |
| `connection_guide` | Complete connection guide with security notes |

### Comprehensive Information

| Name | Description |
|------|-------------|
| `vm_summary` | Comprehensive VM summary |
| `vm_image` | VM image information |
| `linux_config` | Linux-specific configuration (Linux VMs only) |
| `windows_config` | Windows-specific configuration (Windows VMs only) |

## 🎯 Use Cases

### Development Environment

```hcl
# Windows development workstation
module "dev_windows" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.dev_subnet_id
  resource_group_name = "rg-dev-windows"
  vm_name             = "dev-workstation"
  admin_username      = "developer"
  admin_password      = "DevPassword123!"
  enable_public_ip    = true
  vm_size             = "Standard_D4s_v3"
  create_nsg          = true
  
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

# Linux development server
module "dev_linux" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.dev_subnet_id
  resource_group_name = "rg-dev-linux"
  os_type             = "Linux"
  vm_name             = "dev-server"
  admin_username      = "developer"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  enable_public_ip    = true
  vm_size             = "Standard_D4s_v3"
  create_nsg          = true
  
  nsg_rules = [
    {
      name                       = "AllowSSHFromHome"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "YOUR.HOME.IP/32"
      destination_address_prefix = "*"
    }
  ]
}
```

### Production Multi-Tier Application

```hcl
# Windows web tier
module "prod_web_windows" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.web_subnet_id
  resource_group_name = "rg-prod-web"
  vm_name             = "prod-web-01"
  admin_username      = "webadmin"
  admin_password      = "SecureWebPass123!"
  enable_public_ip    = true
  vm_size             = "Standard_D8s_v3"
  os_disk_type        = "Premium_LRS"
  create_nsg          = true
  
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

# Linux application tier
module "prod_app_linux" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.app_subnet_id
  resource_group_name = "rg-prod-app"
  os_type             = "Linux"
  vm_name             = "prod-app-01"
  admin_username      = "appadmin"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  vm_size             = "Standard_E8s_v3"
  os_disk_type        = "Premium_LRS"
  create_nsg          = true
  
  nsg_rules = [
    {
      name                       = "AllowAppFromWeb"
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

# Windows database tier
module "prod_db_windows" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.db_subnet_id
  resource_group_name = "rg-prod-db"
  vm_name             = "prod-db-01"
  admin_username      = "dbadmin"
  admin_password      = "SecureDbPass123!"
  vm_size             = "Standard_E16s_v3"
  os_disk_type        = "Premium_LRS"
  create_nsg          = true
  
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

## 🔄 Migration Guide

### From Windows-Only Module

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
  resource_group_name = "rg-vm-prod"  # Now required
  enable_public_ip = true
  create_nsg       = true  # Now explicit
  # os_type = "Windows" (default - backward compatible)
  
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

### Key Changes

1. **Authentication is now explicit** - No auto-generation of passwords
2. **NSG behavior changed** - NSG creation is now optional and independent
3. **Linux support added** - Full Linux VM support with SSH keys
4. **Image defaults configurable** - Customize default images for your organization
5. **More variables available** - Previously hardcoded values are now configurable

## 🔒 Security Best Practices

### 1. Authentication Security
- **Windows**: Always provide strong passwords, consider using Azure Key Vault
- **Linux**: Prefer SSH key authentication over passwords
- **Hybrid Linux**: Use both SSH keys and passwords for maximum flexibility

### 2. Network Security
- **Internal VMs**: No NSG (rely on subnet-level security)
- **Public VMs**: Create NSG with explicit rules for required access
- **Principle of least privilege**: Only allow necessary ports and sources

### 3. Image Security
- **Use latest images**: Default to "latest" version for security updates
- **Organizational standards**: Customize image defaults for compliance
- **Regular updates**: Keep base images updated in your defaults

## 📚 Additional Resources

- [Azure VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)
- [Azure NSG Rules](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [SSH Key Management](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ssh-from-windows)
- [OpenTofu Documentation](https://opentofu.org/docs/)

## 🤝 Contributing

This module follows security-first principles and supports both Windows and Linux workloads. When contributing:
- No automatic security rules or credential generation
- Explicit configuration over implicit behavior
- Comprehensive validation and documentation
- Maintain backward compatibility for Windows VMs
- Support all common Linux authentication patterns
