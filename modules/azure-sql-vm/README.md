# Azure SQL Server VM OpenTofu Module

A highly specialized and secure OpenTofu module for deploying **SQL Server 2022 Virtual Machines** on Azure with dedicated data and log disks, following security-first design principles and providing comprehensive SQL Server-specific configuration options.

## 🚀 Key Features

✅ **SQL Server 2022 Marketplace Images** - Pre-configured SQL Server 2022 Standard/Enterprise/Express  
✅ **Multi-Disk Storage Architecture** - Separate disks for OS, data files, and transaction logs  
✅ **Security-First Design** - No automatic security rules, explicit NSG configuration required  
✅ **Minimal Required Input** - Only 3 required variables: `subnet_id`, `resource_group_name`, `admin_password`  
✅ **SQL Server Optimized Defaults** - VM sizes, storage types, and configurations optimized for SQL Server  
✅ **Comprehensive Validation** - Extensive validation rules for SQL Server best practices  
✅ **Complete Connection Guide** - RDP and SQL Server connection strings with post-deployment steps  
✅ **ALZ Integration** - Works seamlessly with hub-spoke and single-vnet architectures  

## 🔧 Requirements

- OpenTofu >= 1.0
- Azure Provider >= 3.0
- Existing subnet for VM deployment
- Administrator password for SQL Server VM

## 📋 Quick Start

### Minimal SQL Server VM (Only Required Variables)

```hcl
module "sql_server" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = "/subscriptions/your-sub/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/subnet-db"
  resource_group_name = "rg-sql-prod"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
}
```

**What you get with minimal configuration:**
- SQL Server 2022 Standard on Windows Server 2022
- Standard_D4s_v3 VM (4 vCPU, 16GB RAM) - SQL optimized
- 100GB Premium_LRS data disk (ReadOnly caching)
- 50GB Premium_LRS log disk (None caching)
- Private IP only (no public access)
- No NSG (uses subnet-level security)
- Comprehensive auto-tagging

### Production SQL Server with Custom Configuration

```hcl
module "sql_server_prod" {
  source = "./modules/azure-sql-vm"
  
  # Required variables
  subnet_id           = var.db_subnet_id
  resource_group_name = "rg-sql-prod"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  
  # SQL Server configuration
  vm_name        = "sql-prod-01"
  vm_size        = "Standard_E8s_v3"  # 8 vCPU, 64GB RAM
  sql_edition    = "Enterprise"
  
  # Custom storage configuration
  data_disk_config = {
    size_gb              = 500
    storage_account_type = "Premium_LRS"
    caching              = "ReadOnly"
    lun                  = 0
  }
  
  log_disk_config = {
    size_gb              = 100
    storage_account_type = "Premium_LRS"
    caching              = "None"
    lun                  = 1
  }
  
  # Network security (explicit rules required)
  create_nsg = true
  sql_nsg_rules = [
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
    },
    {
      name                       = "AllowRDPFromMgmt"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "10.0.1.0/24"  # Management subnet
      destination_address_prefix = "*"
    }
  ]
  
  tags = {
    environment = "Production"
    application = "ERP Database"
    backup_required = "true"
  }
}
```

## 🏗️ Storage Architecture

The module implements SQL Server best practices with a three-disk architecture:

### Disk Configuration

| Disk Type | Purpose | Default Size | Default Type | Caching | LUN |
|-----------|---------|--------------|--------------|---------|-----|
| **OS Disk** | Operating System + SQL Server Binaries | Image Default | Premium_LRS | ReadWrite | N/A |
| **Data Disk** | SQL Server Database Files (.mdf) | 100GB | Premium_LRS | ReadOnly | 0 |
| **Log Disk** | SQL Server Transaction Logs (.ldf) | 50GB | Premium_LRS | None | 1 |

### Storage Best Practices Implemented

- **Data Disk**: ReadOnly caching for optimal read performance
- **Log Disk**: No caching for write-intensive transaction log operations
- **Premium_LRS**: High-performance storage for production workloads
- **Separate LUNs**: Proper disk separation for SQL Server performance

## 🖥️ SQL Server Configuration

### Supported SQL Server Editions

```hcl
# SQL Server 2022 Express (Free)
sql_edition = "Express"

# SQL Server 2022 Standard (Default)
sql_edition = "Standard"

# SQL Server 2022 Enterprise
sql_edition = "Enterprise"
```

### VM Size Recommendations

| Workload Type | Recommended VM Size | vCPU | RAM | Use Case |
|---------------|-------------------|------|-----|----------|
| **Development** | Standard_D2s_v3 | 2 | 8GB | Dev/Test environments |
| **Small Production** | Standard_D4s_v3 | 4 | 16GB | Small databases |
| **Medium Production** | Standard_E8s_v3 | 8 | 64GB | Medium databases |
| **Large Production** | Standard_E16s_v3 | 16 | 128GB | Large databases |
| **Memory Intensive** | Standard_M8ms | 8 | 218GB | In-memory workloads |

## 🔒 Security Examples

### 1. Internal SQL Server (No NSG - Recommended)

```hcl
module "internal_sql" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = var.internal_db_subnet_id
  resource_group_name = "rg-sql-internal"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  vm_name             = "sql-internal-01"
  
  # No NSG - relies on subnet-level security (most secure)
  # create_nsg = false (default)
}
```

### 2. Application Tier SQL Server

```hcl
module "app_sql" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = var.app_db_subnet_id
  resource_group_name = "rg-sql-app"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  vm_name             = "sql-app-01"
  
  # Explicit NSG rules for application access
  create_nsg = true
  sql_nsg_rules = [
    {
      name                       = "AllowSQLFromAppTier"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.2.0/24"  # App tier subnet
      destination_address_prefix = "*"
    }
  ]
}
```

### 3. Management SQL Server with RDP Access

```hcl
module "mgmt_sql" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = var.mgmt_subnet_id
  resource_group_name = "rg-sql-mgmt"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  vm_name             = "sql-mgmt-01"
  enable_public_ip    = true  # Management access
  
  create_nsg = true
  sql_nsg_rules = [
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
    },
    {
      name                       = "AllowSQLFromOffice"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "203.0.113.0/24"  # Office IP range
      destination_address_prefix = "*"
    }
  ]
}
```

## 📝 Variables

### Required Variables (Minimal Requirements)

| Name | Description | Type |
|------|-------------|------|
| `subnet_id` | ID of the subnet where the SQL Server VM will be deployed | `string` |
| `resource_group_name` | Name for the resource group | `string` |
| `admin_username` | Administrator username for the SQL Server VM | `string` |
| `admin_password` | Administrator password for the SQL Server VM | `string` |

### Core Configuration (Smart Defaults)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vm_name` | Name of the SQL Server VM (auto-generated if null) | `string` | `null` |
| `vm_size` | VM size optimized for SQL Server workloads | `string` | `"Standard_D4s_v3"` |
| `location` | Azure region | `string` | `"West Europe"` |
| `sql_edition` | SQL Server edition | `string` | `"Standard"` |

### SQL Server Image Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `sql_image_defaults` | SQL Server image configuration | `object` | SQL Server 2022 Standard |
| `image_version` | SQL Server image version | `string` | `"latest"` |

### Storage Configuration (SQL Server Optimized)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `os_disk_type` | OS disk storage type | `string` | `"Premium_LRS"` |
| `data_disk_config` | Data disk configuration | `object` | 100GB Premium_LRS |
| `log_disk_config` | Log disk configuration | `object` | 50GB Premium_LRS |

### Network Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_public_ip` | Whether to create a public IP | `bool` | `false` |
| `private_ip_allocation` | Private IP allocation method | `string` | `"Dynamic"` |

### Security Configuration (Security-First)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_nsg` | Whether to create NSG | `bool` | `false` |
| `sql_nsg_rules` | List of NSG rules | `list(object)` | `[]` |

### SQL Server Specific Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `sql_port` | SQL Server port number | `number` | `1433` |
| `sql_connectivity_type` | SQL connectivity type | `string` | `"PRIVATE"` |
| `sql_authentication_type` | SQL authentication type | `string` | `"SQL"` |

## 📤 Outputs

### Core VM Information

| Name | Description |
|------|-------------|
| `vm_id` | SQL Server VM ID |
| `vm_name` | SQL Server VM name |
| `vm_size` | SQL Server VM size |
| `private_ip_address` | Private IP address |
| `public_ip_address` | Public IP address (if enabled) |

### SQL Server Specific Outputs

| Name | Description |
|------|-------------|
| `sql_server_edition` | SQL Server edition |
| `sql_server_port` | SQL Server port |
| `sql_connection_string` | SQL Server connection string |
| `rdp_connection_string` | RDP connection command |

### Storage Information

| Name | Description |
|------|-------------|
| `data_disk_id` | Data disk ID |
| `data_disk_size_gb` | Data disk size |
| `log_disk_id` | Log disk ID |
| `log_disk_size_gb` | Log disk size |
| `disk_configuration` | Complete disk configuration summary |

### Comprehensive Outputs

| Name | Description |
|------|-------------|
| `sql_vm_summary` | Complete SQL Server VM summary |
| `sql_connection_guide` | Detailed connection and setup guide |
| `resource_names` | All created resource names |

## 🎯 Use Cases

### Development Environment

```hcl
module "dev_sql" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = var.dev_subnet_id
  resource_group_name = "rg-sql-dev"
  admin_username      = "devadmin"
  admin_password      = "DevSQLPassword123!"
  
  vm_name     = "sql-dev-01"
  vm_size     = "Standard_D2s_v3"  # Smaller for dev
  sql_edition = "Express"          # Free for development
  
  # Smaller disks for development
  data_disk_config = {
    size_gb              = 50
    storage_account_type = "StandardSSD_LRS"  # Cost-effective
    caching              = "ReadOnly"
    lun                  = 0
  }
  
  log_disk_config = {
    size_gb              = 20
    storage_account_type = "StandardSSD_LRS"
    caching              = "None"
    lun                  = 1
  }
  
  enable_public_ip = true  # Easy access for developers
  create_nsg = true
  sql_nsg_rules = [
    {
      name                       = "AllowRDPFromDev"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "YOUR.DEV.IP/32"
      destination_address_prefix = "*"
    }
  ]
}
```

### High-Availability Production Setup

```hcl
# Primary SQL Server
module "sql_primary" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = var.db_subnet_id
  resource_group_name = "rg-sql-ha-primary"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  
  vm_name     = "sql-primary-01"
  vm_size     = "Standard_E16s_v3"  # High-performance
  sql_edition = "Enterprise"        # Always On support
  zone        = "1"                 # Availability Zone 1
  
  # High-performance storage
  data_disk_config = {
    size_gb              = 1000
    storage_account_type = "Premium_LRS"
    caching              = "ReadOnly"
    lun                  = 0
  }
  
  log_disk_config = {
    size_gb              = 200
    storage_account_type = "Premium_LRS"
    caching              = "None"
    lun                  = 1
  }
  
  create_nsg = true
  sql_nsg_rules = [
    {
      name                       = "AllowSQLFromApp"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.2.0/24"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowAlwaysOnEndpoint"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5022"
      source_address_prefix      = "10.0.3.0/24"  # DB subnet
      destination_address_prefix = "*"
    }
  ]
  
  tags = {
    environment = "Production"
    role        = "Primary"
    backup      = "Required"
    monitoring  = "Critical"
  }
}

# Secondary SQL Server (similar configuration with zone = "2")
```

## 🔄 Integration with ALZ Architecture

### Hub-Spoke Deployment

```hcl
# Deploy SQL Server in spoke VNet
module "sql_spoke" {
  source = "./modules/azure-sql-vm"
  
  # Use spoke subnet
  subnet_id           = module.spoke_networking["database"].subnet_ids["subnet-db"]
  resource_group_name = "rg-sql-spoke"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  
  vm_name = "sql-spoke-01"
  
  # Internal access only (no public IP)
  create_nsg = true
  sql_nsg_rules = [
    {
      name                       = "AllowSQLFromAppSpoke"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.2.0.0/20"  # App spoke CIDR
      destination_address_prefix = "*"
    }
  ]
}
```

### Single VNet Deployment

```hcl
# Deploy SQL Server in single VNet
module "sql_single" {
  source = "./modules/azure-sql-vm"
  
  subnet_id           = module.single_networking[0].subnet_ids["subnet-db"]
  resource_group_name = "rg-sql-single"
  admin_username      = "sqladmin"
  admin_password      = "SecureSQLPassword123!"
  
  vm_name = "sql-single-01"
}
```

## 🚀 Post-Deployment Steps

After deploying the SQL Server VM, follow these steps:

### 1. Connect to the VM

```bash
# Use the RDP connection string from outputs
mstsc /v:<public_or_private_ip>
```

### 2. Initialize Data and Log Disks

```powershell
# In the VM, open PowerShell as Administrator
# Initialize the data disk (LUN 0)
Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Where-Object Number -eq 2 | Initialize-Disk -PartitionStyle GPT
New-Partition -DiskNumber 2 -UseMaximumSize -DriveLetter F
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel "SQL_Data"

# Initialize the log disk (LUN 1)
Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Where-Object Number -eq 3 | Initialize-Disk -PartitionStyle GPT
New-Partition -DiskNumber 3 -UseMaximumSize -DriveLetter G
Format-Volume -DriveLetter G -FileSystem NTFS -NewFileSystemLabel "SQL_Logs"
```

### 3. Configure SQL Server Storage

```sql
-- Move system databases to new disks
-- Connect to SQL Server Management Studio
-- Move tempdb, model, and msdb to F: drive
-- Configure default database and log file locations
```

### 4. Test SQL Server Connectivity

```bash
# Use the SQL connection string from outputs
sqlcmd -S <server_address>,1433 -U sa -P <password>
```

## 🔧 Troubleshooting

### Common Issues

1. **VM Size Validation Error**
   - Ensure VM size is from the approved SQL Server list
   - Check regional availability of the selected VM size

2. **Disk LUN Conflicts**
   - Verify data_disk_config.lun and log_disk_config.lun are different
   - LUN values must be between 0 and 63

3. **NSG Rule Priority Conflicts**
   - Ensure all NSG rule priorities are unique
   - Priorities must be between 100 and 4096

4. **SQL Server Connection Issues**
   - Verify NSG rules allow traffic on the configured SQL port
   - Check Windows Firewall settings on the VM
   - Confirm SQL Server is configured for network connections

## 📚 Additional Resources

- [SQL Server on Azure VMs Best Practices](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/performance-guidelines-best-practices)
- [Azure VM Sizes for SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sizes-general)
- [SQL Server Storage Configuration](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/storage-configuration)
- [OpenTofu Documentation](https://opentofu.org/docs/)

## 🤝 Contributing

This module follows the security-first principles outlined in the MODULE-GENERALIZATION-GUIDE.md. When contributing:
- No automatic security rules or credential generation
- Explicit configuration over implicit behavior
- Comprehensive validation and documentation
- SQL Server best practices implementation
- Support for both development and production scenarios

## 🏆 Module Benefits

### Security-First Design
- **No automatic security rules** - Users must explicitly define access
- **Principle of least privilege** - Private by default, public by choice
- **Explicit NSG configuration** - No hidden security assumptions

### SQL Server Optimized
- **Multi-disk architecture** - Separate data and log disks for performance
- **SQL Server marketplace images** - Pre-configured and optimized
- **Performance-optimized defaults** - VM sizes and storage types for SQL Server
- **Comprehensive validation** - SQL Server specific validation rules

### Operational Excellence
- **Minimal required variables** - Only 3 required, everything else has smart defaults
- **Comprehensive outputs** - Connection strings, disk information, setup guides
- **Auto-tagging** - Detailed tagging for cost management and governance
- **ALZ integration** - Works with both hub-spoke and single-vnet architectures

### Developer Experience
- **Clear documentation** - Extensive examples and use cases
- **Validation feedback** - Clear error messages for misconfigurations
- **Connection guides** - Step-by-step setup and connection instructions
- **Troubleshooting** - Common issues and solutions documented
