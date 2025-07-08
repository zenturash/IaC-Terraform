# Azure Guest Configuration - Datto RMM Deployment Scripts

This directory contains PowerShell scripts for creating and deploying Azure Guest Configuration packages to install Datto RMM agents across multiple customer tenants in an MSP environment.

## Overview

The Guest Configuration approach provides a more robust and scalable solution compared to VM extensions, offering:

- ✅ **No Extension Conflicts**: Works alongside existing VM extensions
- ✅ **Better Error Handling**: DSC provides robust installation logic
- ✅ **Multi-Tenant Support**: Central package hosting with cross-tenant deployment
- ✅ **Compliance Monitoring**: Built-in compliance reporting
- ✅ **Parameterization**: Per-customer Site GUID support

## Architecture

```
MSP Tenant (Your Tenant)
├── Storage Account (Central Package Repository)
│   ├── Container: guest-configurations
│   │   └── InstallDattoRMM.zip (Guest Configuration Package)
│   └── SAS Token (Read-only, 1-year expiry)
│
Customer Tenants
├── Guest Configuration Policy Assignment
├── Site GUID Parameter (per customer)
└── Automatic Datto RMM Installation
```

## Scripts Overview

| Script | Purpose | Usage |
|--------|---------|-------|
| `InstallDattoRMM.ps1` | DSC Configuration for Datto RMM installation | Core configuration file |
| `Compile-DattoRMMConfig.ps1` | Compiles DSC into MOF files | Creates MOF for packaging |
| `Create-GuestConfigPackage.ps1` | Creates Guest Configuration ZIP package | Packages MOF for deployment |
| `Setup-CentralStorage.ps1` | Sets up Azure Storage in MSP tenant | Creates central infrastructure |

## Quick Start Guide

### Step 1: Set Up Central Storage (MSP Tenant)

First, create the central storage infrastructure in your MSP tenant:

```powershell
# Run in your MSP tenant
.\Setup-CentralStorage.ps1 -StorageAccountName "mspguestconfig2025"
```

This creates:
- Resource group: `rg-msp-guestconfig`
- Storage account with globally unique name
- Container: `guest-configurations`
- SAS token for cross-tenant access (1-year expiry)

**Output**: SAS URL for use in customer tenant policies

### Step 2: Compile DSC Configuration

Compile the DSC configuration with a test Site GUID:

```powershell
# Compile for testing (use any valid GUID for initial package)
.\Compile-DattoRMMConfig.ps1 -SiteGuid "ff01b552-a4cb-415e-b3c2-c6581a067479" -CustomerName "Test Customer"
```

**Output**: `localhost.mof` file in `.\Output` directory

### Step 3: Create Guest Configuration Package

Create the ZIP package for Azure Guest Configuration:

```powershell
# Create package from compiled MOF
.\Create-GuestConfigPackage.ps1 -MofPath ".\Output" -PackageName "InstallDattoRMM"
```

**Output**: `InstallDattoRMM.zip` in `.\Packages` directory

### Step 4: Upload Package to Central Storage

Upload the package to your MSP storage account:

```powershell
# Using Azure CLI (recommended)
az storage blob upload --account-name "mspguestconfig2025" --container-name "guest-configurations" --name "InstallDattoRMM.zip" --file ".\Packages\InstallDattoRMM.zip" --sas-token "<SAS-TOKEN-FROM-STEP-1>"

# Or using PowerShell (if you have storage context)
Set-AzStorageBlobContent -File ".\Packages\InstallDattoRMM.zip" -Container "guest-configurations" -Blob "InstallDattoRMM.zip" -Context $storageContext
```

## Detailed Usage

### InstallDattoRMM.ps1

Core DSC configuration that defines the Datto RMM installation process.

**Features:**
- Parameterized Site GUID for multi-tenant deployment
- Comprehensive error handling and logging
- Event log integration for monitoring
- Idempotent installation logic
- Multiple validation methods (service, process, registry)

**Parameters:**
- `SiteGuid` (Required): Datto RMM Site GUID
- `CustomerName` (Optional): Customer name for logging

### Compile-DattoRMMConfig.ps1

Compiles the DSC configuration into MOF files.

```powershell
.\Compile-DattoRMMConfig.ps1 -SiteGuid "customer-site-guid" -CustomerName "Customer Name" -OutputPath "C:\DSC\Output"
```

**Features:**
- GUID validation
- MOF content validation
- Compilation summary report
- Error handling and reporting

### Create-GuestConfigPackage.ps1

Creates Azure Guest Configuration packages from MOF files.

```powershell
.\Create-GuestConfigPackage.ps1 -MofPath ".\Output" -PackageName "InstallDattoRMM" -PackageVersion "1.0.0" -Force
```

**Features:**
- Automatic GuestConfiguration module installation
- Package content validation
- ZIP package creation
- Upload-ready output

### Setup-CentralStorage.ps1

Sets up the central Azure Storage infrastructure in your MSP tenant.

```powershell
.\Setup-CentralStorage.ps1 -ResourceGroupName "rg-msp-guestconfig" -StorageAccountName "mspguestconfig2025" -Location "West Europe"
```

**Features:**
- Automatic Azure PowerShell module installation
- Storage account creation with optimal settings
- SAS token generation (1-year expiry)
- Configuration file output for automation

## Multi-Tenant Deployment

### For Each Customer Tenant

1. **Create Guest Configuration Policy Definition** (using the SAS URL from Step 1)
2. **Assign Policy** with customer-specific Site GUID parameter
3. **Monitor Compliance** through Azure Policy dashboard

### Example Policy Assignment

```json
{
  "parameters": {
    "SiteGuid": {
      "value": "customer-specific-site-guid"
    },
    "CustomerName": {
      "value": "Customer A Corp"
    }
  }
}
```

## Monitoring and Troubleshooting

### Event Log Monitoring

The DSC configuration writes to Windows Event Log:
- **Source**: `DattoRMM-DSC`
- **Log**: Application
- **Event IDs**:
  - 1000: Event log source created
  - 1001-1007: Installation progress
  - 1999: Installation errors

### PowerShell Monitoring

```powershell
# Check for Datto RMM installation events
Get-EventLog -LogName Application -Source "DattoRMM-DSC" -Newest 10

# Check for Datto RMM services
Get-Service -Name "*Datto*"

# Check for Datto RMM processes
Get-Process -Name "*Datto*"
```

### Azure Policy Compliance

Monitor compliance through:
- Azure Portal → Policy → Compliance
- Azure CLI: `az policy state list`
- PowerShell: `Get-AzPolicyState`

## Security Considerations

### SAS Token Security

- **Permissions**: Read and List only
- **Expiry**: 1 year (rotate before expiry)
- **Scope**: Container-level access only
- **Storage**: Keep token secure, don't commit to source control

### Cross-Tenant Access

- Customer tenants have no direct access to your storage account
- Access is limited to the specific Guest Configuration package
- All access is logged in your MSP tenant

## Troubleshooting

### Common Issues

1. **GuestConfiguration Module Not Found**
   ```powershell
   Install-Module -Name "GuestConfiguration" -Force -AllowClobber -Scope CurrentUser
   ```

2. **Azure PowerShell Module Not Found**
   ```powershell
   Install-Module -Name "Az" -Force -AllowClobber -Scope CurrentUser
   ```

3. **Storage Account Name Not Available**
   - Try a different name (must be globally unique)
   - Use numbers or different suffix

4. **SAS Token Expired**
   - Re-run `Setup-CentralStorage.ps1` to generate new token
   - Update policy definitions with new SAS URL

5. **MOF Compilation Fails**
   - Ensure PowerShell 5.1 or later
   - Check DSC configuration syntax
   - Verify GUID format

### Validation Commands

```powershell
# Test DSC configuration syntax
Test-DscConfiguration -Path ".\Output\localhost.mof"

# Validate Guest Configuration package
Test-GuestConfigurationPackage -Path ".\Packages\InstallDattoRMM.zip"

# Test storage account connectivity
Test-NetConnection -ComputerName "mspguestconfig2025.blob.core.windows.net" -Port 443
```

## File Structure

```
guest-config-scripts/
├── InstallDattoRMM.ps1              # DSC Configuration
├── Compile-DattoRMMConfig.ps1       # MOF Compilation
├── Create-GuestConfigPackage.ps1    # Package Creation
├── Setup-CentralStorage.ps1         # Storage Setup
├── README.md                        # This file
├── Output/                          # MOF compilation output
│   ├── localhost.mof
│   └── compilation-summary.txt
├── Packages/                        # Guest Configuration packages
│   ├── InstallDattoRMM.zip
│   └── InstallDattoRMM-package-summary.txt
├── msp-storage-config.json          # Storage configuration
└── msp-storage-summary.txt          # Storage setup summary
```

## Next Steps

After completing the PowerShell setup:

1. **Test the Package**: Deploy to a test VM to verify installation
2. **Create Terraform Module**: Automate the entire process with OpenTofu/Terraform
3. **Policy Definitions**: Create reusable Guest Configuration policy definitions
4. **Customer Deployment**: Roll out to customer tenants with their specific Site GUIDs

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the generated summary files
3. Check Azure Activity Logs for deployment issues
4. Verify SAS token permissions and expiry

---

**Author**: MSP Automation Team  
**Version**: 1.0  
**Last Updated**: January 2025
