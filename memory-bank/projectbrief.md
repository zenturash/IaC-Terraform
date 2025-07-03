# Azure VM OpenTofu Module - Project Brief

## Project Overview
Create a simple proof of concept (POC) OpenTofu project with a reusable module for deploying Azure Virtual Machines with all necessary components.

## Core Requirements
- **Technology**: OpenTofu (not Terraform)
- **Cloud Provider**: Microsoft Azure
- **Target Region**: West Europe
- **Purpose**: Simple POC for VM deployment

## VM Specifications
- **Operating System**: Windows Server 2025
- **Authentication**: Password-based (no SSH keys)
- **VM Size**: Configurable parameter
- **VM Name**: Configurable parameter

## Network Architecture
- **Virtual Network**: /20 CIDR block
- **Subnet**: /24 subnet within the VNet
- **Security**: No NSG required (using Azure defaults)
- **Public IP**: Optional (configurable)

## Resource Management
- **Resource Group**: Module creates its own RG
- **Naming**: Configurable resource group and VM names
- **Location**: West Europe (configurable)

## Tagging Strategy
All resources tagged with:
- Creation date
- Creation method (OpenTofu)
- OS type and VM size
- Environment (POC)
- Project identifier

## Success Criteria
- Functional OpenTofu module for Azure VM deployment
- Configurable VM name and size parameters
- Complete networking setup (VNet, subnet, NIC)
- Proper resource tagging
- Example usage documentation
- Reusable and maintainable code structure
