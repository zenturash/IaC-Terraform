# Technical Context - Azure VM OpenTofu Module

## Technology Stack
- **Infrastructure as Code**: OpenTofu (open-source Terraform fork)
- **Cloud Provider**: Microsoft Azure
- **Target OS**: Windows Server 2025
- **Authentication**: Azure CLI or Service Principal
- **Version Control**: Git (implied)

## OpenTofu Configuration
- **Provider**: AzureRM provider for Azure resource management
- **State Management**: Local state (can be configured for remote)
- **Module Structure**: Standard Terraform/OpenTofu module layout
- **Version Constraints**: Latest stable OpenTofu and AzureRM provider

## Azure Resources Architecture
```
Resource Group
├── Virtual Network (/20 CIDR)
│   └── Subnet (/24 CIDR)
├── Network Interface
│   ├── Private IP (dynamic)
│   └── Public IP (optional)
├── Virtual Machine
│   ├── OS: Windows Server 2025
│   ├── Size: Configurable (e.g., Standard_B2s)
│   └── Authentication: Password
└── Managed Disk (OS Disk)
    ├── Type: Premium_LRS (default)
    └── Size: 127 GB (default)
```

## Development Setup Requirements
- OpenTofu CLI installed
- Azure CLI installed and authenticated
- Azure subscription with appropriate permissions
- Text editor or IDE with HCL syntax support

## Key Technical Decisions
1. **OpenTofu over Terraform**: User preference for open-source solution
2. **Password Authentication**: Simplified setup, no SSH key management
3. **No NSG**: Relying on Azure default security for POC simplicity
4. **Module Creates RG**: Self-contained module approach
5. **Dynamic Tagging**: Automatic date and metadata tagging

## File Structure Standards
- `main.tf`: Primary resource definitions
- `variables.tf`: Input variable declarations
- `outputs.tf`: Output value definitions
- `versions.tf`: Provider and version constraints
- `README.md`: Documentation and usage examples

## Networking Configuration
- **VNet CIDR**: 10.0.0.0/20 (default, configurable)
- **Subnet CIDR**: 10.0.1.0/24 (default, configurable)
- **Private IP**: Dynamic allocation from subnet
- **Public IP**: Optional, Standard SKU
- **DNS**: Azure-provided DNS

## Security Considerations
- Password complexity requirements enforced
- No NSG (as requested) - relies on Azure platform security
- Optional public IP for external access
- RDP access available if public IP enabled

## Performance Considerations
- Default VM size: Standard_B2s (burstable, cost-effective for POC)
- Premium SSD for OS disk (better performance)
- Single availability zone deployment (POC simplicity)

## Extensibility Points
- VM size parameterization
- Network CIDR customization
- Additional disk attachment capability
- Multiple VM deployment support
- Custom tagging extension
