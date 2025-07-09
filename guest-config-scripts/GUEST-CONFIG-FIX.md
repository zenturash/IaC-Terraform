# Guest Configuration Fix Guide

## Problem Identified

The Guest Configuration assignment is failing with the error:
**"Resource instance with id 'InstallDattoRMM' is not found in DSC document."**

## Root Cause Analysis

1. **Current MOF file contains hardcoded values** instead of parameterized configuration
2. **Guest Configuration expects runtime parameters** but our MOF was compiled with fixed Site GUID
3. **Parameter injection mechanism mismatch** between policy and DSC configuration

## Current vs Required Approach

### ❌ Current (Broken) Approach
```powershell
# Compilation with hardcoded values
InstallDattoRMM -SiteGuid "ff01b552-a4cb-415e-b3c2-c6581a067479" -CustomerName "Test Customer"
```
**Result**: MOF contains hardcoded values, can't accept runtime parameters

### ✅ Required (Fixed) Approach
```powershell
# Compilation without parameters for Guest Configuration
InstallDattoRMM  # No parameters - creates template
```
**Result**: MOF template that accepts parameters at runtime via Guest Configuration

## Solution Steps

### Step 1: Use the Correct DSC Configuration

Use `InstallDattoRMM-GuestConfig.ps1` instead of `InstallDattoRMM.ps1`:

**Key Differences:**
- No configuration parameters (Guest Configuration handles this)
- Uses `$Node.SiteGuid` and `$Node.CustomerName` for runtime parameter injection
- Designed specifically for Guest Configuration deployment

### Step 2: Compile Without Parameters

```powershell
# Run the new compilation script
.\Compile-DattoRMM-GuestConfig.ps1 -OutputPath ".\Output"
```

This creates a parameterized MOF file that Guest Configuration can use.

### Step 3: Create New Guest Configuration Package

```powershell
# Create package with the new MOF
.\Create-GuestConfigPackage.ps1 -MofPath ".\Output" -PackageName "InstallDattoRMM" -Force
```

### Step 4: Upload New Package

Upload the new package to your storage account, replacing the old one.

### Step 5: Update Content Hash

The new package will have a different SHA256 hash. Update the policy with the new hash.

## Quick Fix Commands

```powershell
# Navigate to guest-config-scripts directory
cd guest-config-scripts

# 1. Compile new parameterized MOF
.\Compile-DattoRMM-GuestConfig.ps1

# 2. Create new Guest Configuration package
.\Create-GuestConfigPackage.ps1 -MofPath ".\Output" -Force

# 3. Get the new package hash
Get-FileHash ".\Packages\InstallDattoRMM.zip" -Algorithm SHA256

# 4. Upload new package to storage
az storage blob upload --account-name "zenturamspguestconfig" --container-name "guest-configurations" --name "InstallDattoRMM.zip" --file ".\Packages\InstallDattoRMM.zip" --overwrite --sas-token "YOUR-SAS-TOKEN"
```

## Policy Configuration Verification

Ensure your policy has the correct parameter structure:

```json
"configurationParameter": [
  {
    "name": "InstallDattoRMM;SiteGuid",
    "value": "[parameters('siteGuid')]"
  },
  {
    "name": "InstallDattoRMM;CustomerName", 
    "value": "[parameters('customerName')]"
  }
]
```

## Testing the Fix

1. **Compile the new MOF** using `Compile-DattoRMM-GuestConfig.ps1`
2. **Verify no hardcoded values** in the MOF file
3. **Create new package** and upload to storage
4. **Update policy** with new content hash
5. **Test on a VM** to verify Guest Configuration works

## Expected Behavior After Fix

- ✅ Guest Configuration assignment shows "Compliant"
- ✅ Parameters are injected at runtime
- ✅ Datto RMM agent installs with correct Site GUID
- ✅ Event logs show customer-specific information

## Files Created for Fix

1. `InstallDattoRMM-GuestConfig.ps1` - Corrected DSC configuration
2. `Compile-DattoRMM-GuestConfig.ps1` - Parameterized compilation script
3. `GUEST-CONFIG-FIX.md` - This guide

## Next Steps

1. Run the fix commands above
2. Update the Terraform policy with new content hash
3. Test the deployment on a VM
4. Monitor Guest Configuration compliance

The key insight is that Guest Configuration requires a different approach to parameter handling than traditional DSC deployments.
