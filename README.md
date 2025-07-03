# Azure VM OpenTofu Module

A simple proof-of-concept (POC) OpenTofu module for creating Azure Virtual Machines with all necessary networking components.

## Features

- **Complete Infrastructure**: Creates Resource Group, Virtual Network, Subnet, Network Interface, and Virtual Machine
- **Windows Server 2025**: Latest Windows Server with password authentication
- **Configurable**: VM name, size, and network settings are customizable
- **Optional Public IP**: Enable/disable public IP assignment
- **Comprehensive Tagging**: Automatic tagging with creation date and metadata
- **Self-contained**: Module creates its own resource group

## Quick Start

### Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- Azure subscription with appropriate permissions

### Authentication

Authenticate with Azure CLI:
```bash
az login
az account set --subscription "your-subscription-id"
```

### Basic Usage

1. **Clone or download this repository**

2. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars with your values:**
   ```hcl
   vm_name        = "my-poc-vm"
   admin_username = "azureuser"
   admin_password = "YourSecurePassword123!"
   ```

4. **Initialize and apply:** -auto-approve
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

5. **Connect to your VM:**
   After deployment, use the RDP connection string from the output to connect to your VM.

## Module Usage

### Basic Example

```hcl
module "vm" {
  source = "./modules/azure-vm"

  vm_name        = "poc-vm-01"
  admin_username = "azureuser"
  admin_password = "YourSecurePassword123!"
  
  vm_size          = "Standard_B2s"
  location         = "West Europe"
  enable_public_ip = true
}
```

### Advanced Example

```hcl
module "vm" {
  source = "./modules/azure-vm"

  # Required
  vm_name        = "production-vm"
  admin_username = "adminuser"
  admin_password = "ComplexPassword123!"
  
  # Optional customization
  vm_size             = "Standard_D2s_v3"
  location            = "North Europe"
  resource_group_name = "rg-production"
  enable_public_ip    = false
  
  # Network customization
  vnet_cidr   = "172.16.0.0/20"
  subnet_cidr = "172.16.1.0/24"
  
  # Storage customization
  os_disk_type = "StandardSSD_LRS"
}
```

## Configuration

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vm_name` | string | Name of the virtual machine |
| `admin_username` | string | Administrator username |
| `admin_password` | string | Administrator password (12-123 characters) |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_size` | string | `Standard_B2s` | Azure VM size |
| `location` | string | `West Europe` | Azure region |
| `resource_group_name` | string | `rg-vm-poc` | Base name for resource group |
| `enable_public_ip` | bool | `true` | Create public IP |
| `vnet_cidr` | string | `10.0.0.0/20` | Virtual network CIDR |
| `subnet_cidr` | string | `10.0.1.0/24` | Subnet CIDR |
| `os_disk_type` | string | `Premium_LRS` | OS disk storage type |

### Supported VM Sizes

- `Standard_B1s`, `Standard_B2s`, `Standard_B4ms`
- `Standard_D2s_v3`, `Standard_D4s_v3`, `Standard_D8s_v3`
- `Standard_E2s_v3`, `Standard_E4s_v3`, `Standard_E8s_v3`
- `Standard_F2s_v2`, `Standard_F4s_v2`, `Standard_F8s_v2`

## Outputs

| Output | Description |
|--------|-------------|
| `vm_name` | Name of the created VM |
| `vm_id` | Azure resource ID of the VM |
| `resource_group_name` | Name of the created resource group |
| `private_ip_address` | Private IP address |
| `public_ip_address` | Public IP address (if enabled) |
| `rdp_connection_string` | RDP connection command |
| `virtual_network_name` | Name of the virtual network |
| `subnet_name` | Name of the subnet |
| `tags` | Applied resource tags |

## Project Structure

```
.
├── modules/
│   └── azure-vm/           # Reusable VM module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── examples/
│   └── basic-vm/           # Usage example
├── memory-bank/            # Project documentation
├── main.tf                 # Root configuration
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```

## Resource Tagging

All resources are automatically tagged with:
- `creation_date`: Current date
- `creation_method`: "OpenTofu"
- `os_type`: "Windows Server 2025"
- `vm_size`: The VM size used
- `environment`: "POC"
- `project`: "Azure VM POC"

## Security Considerations

- **Password Authentication**: Uses password-based authentication for simplicity
- **No NSG**: Relies on Azure default security (as requested for POC)
- **Public IP**: Optional - can be disabled for private-only access
- **Sensitive Variables**: Password is marked as sensitive

## Resource Lifecycle Management

### Deployment
```bash
# Initialize the project
tofu init

# Review the deployment plan
tofu plan

# Deploy the infrastructure
tofu apply
```

### Resource Dependencies
OpenTofu automatically manages resource dependencies in the correct order:

**Creation Order:**
1. Resource Groups (networking and compute)
2. Virtual Network
3. Subnets
4. Public IP (if enabled)
5. Network Interface
6. Virtual Machine

**Destruction Order:**
1. Virtual Machine
2. Network Interface
3. Public IP
4. Subnets
5. Virtual Network
6. Resource Groups

### Common Issues and Solutions

#### Public IP Deletion Error
If you encounter: `PublicIPAddressCannotBeDeleted: Public IP address ... can not be deleted since it is still allocated to resource`

**Solution:** OpenTofu handles this automatically by destroying resources in dependency order. If you encounter this error:
1. Ensure the VM is destroyed first
2. Run `tofu destroy` again - it will retry the failed resources -auto-approve
3. The public IP will be freed once the network interface is destroyed

#### Resource Group Dependencies
Resource groups are destroyed last to ensure all contained resources are removed first.

### Cleanup

To destroy all created resources:
```bash
tofu destroy
```

**Note:** The destroy process may take 3-5 minutes as Azure needs to properly deallocate all resources.

## Examples

See the `examples/basic-vm/` directory for a complete working example.

## Contributing

This is a POC project focused on simplicity. For production use, consider adding:
- Network Security Groups
- SSH key authentication for Linux VMs
- Backup configuration
- Monitoring setup
- Multiple availability zones

## License

This project is provided as-is for educational and POC purposes.
