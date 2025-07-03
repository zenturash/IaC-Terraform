# Product Context - Azure VM OpenTofu Module

## Why This Project Exists
This OpenTofu module addresses the need for a simple, reusable way to deploy Azure Virtual Machines for proof-of-concept and development scenarios. It eliminates the complexity of manually configuring Azure resources through the portal while providing infrastructure-as-code benefits.

## Problems It Solves
1. **Manual VM Creation**: Removes the need to manually create VMs through Azure Portal
2. **Inconsistent Deployments**: Ensures consistent VM deployments across environments
3. **Missing Infrastructure Components**: Automatically creates all required networking components
4. **Poor Resource Organization**: Implements proper tagging and resource grouping
5. **Lack of Repeatability**: Provides repeatable, version-controlled infrastructure

## How It Should Work
### User Experience
1. User configures basic parameters (VM name, size, credentials)
2. Module automatically creates all required Azure resources:
   - Resource Group
   - Virtual Network with proper CIDR allocation
   - Subnet within the VNet
   - Network Interface
   - Virtual Machine with Windows Server 2025
   - Managed OS disk
   - Optional public IP
3. All resources are properly tagged for identification and management
4. Module outputs key information (IP addresses, resource IDs)

### Key Features
- **Simplicity**: Minimal required parameters
- **Flexibility**: Configurable VM size and naming
- **Completeness**: Creates entire infrastructure stack
- **Best Practices**: Implements proper tagging and resource organization
- **Documentation**: Clear examples and usage instructions

## Target Users
- DevOps engineers setting up development environments
- System administrators creating test VMs
- Developers needing quick Azure VM deployments
- Teams implementing infrastructure-as-code practices

## Success Metrics
- Module can deploy a functional Windows VM in under 10 minutes
- All networking components work correctly
- VM is accessible via RDP (if public IP enabled)
- Resources are properly tagged and organized
- Module is reusable across different scenarios
