<#
.SYNOPSIS
    Sets up Azure Storage Account for Guest Configuration packages in MSP tenant

.DESCRIPTION
    This script creates the central Azure Storage Account infrastructure in your MSP tenant
    for hosting Guest Configuration packages that will be used across multiple customer tenants.

.PARAMETER ResourceGroupName
    Name of the resource group for the storage account

.PARAMETER StorageAccountName
    Name of the storage account (must be globally unique)

.PARAMETER Location
    Azure region for the storage account

.PARAMETER ContainerName
    Name of the container for Guest Configuration packages

.PARAMETER SubscriptionId
    Azure subscription ID for your MSP tenant

.EXAMPLE
    .\Setup-CentralStorage.ps1 -ResourceGroupName "rg-msp-guestconfig" -StorageAccountName "mspguestconfig2025" -Location "West Europe"

.NOTES
    Author: MSP Automation Team
    Version: 1.0
    Requires: Azure PowerShell module and appropriate permissions
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "000_CrossTenant-GuestConfig",
    
    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 24)]
    [ValidatePattern('^[a-z0-9]+$')]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "West Europe",
    
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "guest-configurations",
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Purpose = "Guest Configuration Packages"
        Owner = "MSP Operations"
        Environment = "Production"
        CreatedBy = "PowerShell Automation"
    }
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "=== MSP Central Storage Setup ===" -ForegroundColor Green
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
    Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Yellow
    Write-Host "Location: $Location" -ForegroundColor Yellow
    Write-Host "Container: $ContainerName" -ForegroundColor Yellow
    Write-Host ""

    # Check if Azure PowerShell module is available
    Write-Host "Checking for Azure PowerShell module..." -ForegroundColor Cyan
    $azModule = Get-Module -Name "Az.Accounts" -ListAvailable
    if (-not $azModule) {
        Write-Host "Azure PowerShell module not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name "Az" -Force -AllowClobber -Scope CurrentUser
            Write-Host "Azure PowerShell module installed successfully" -ForegroundColor Green
        } catch {
            throw "Failed to install Azure PowerShell module: $($_.Exception.Message)"
        }
    } else {
        Write-Host "Azure PowerShell module found: Version $($azModule.Version)" -ForegroundColor Green
    }

    # Import required modules
    Import-Module -Name "Az.Accounts" -Force
    Import-Module -Name "Az.Resources" -Force
    Import-Module -Name "Az.Storage" -Force

    # Check if already connected to Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not connected to Azure. Please sign in..." -ForegroundColor Yellow
        Connect-AzAccount
        $context = Get-AzContext
    }

    Write-Host "Connected to Azure:" -ForegroundColor Green
    Write-Host "  Account: $($context.Account.Id)" -ForegroundColor White
    Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
    Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor White

    # Set subscription if specified
    if ($SubscriptionId) {
        Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Cyan
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    # Check if resource group exists, create if not
    Write-Host "Checking resource group: $ResourceGroupName" -ForegroundColor Cyan
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-Host "Resource group created successfully" -ForegroundColor Green
    } else {
        Write-Host "Resource group already exists" -ForegroundColor Green
    }

    # Check if storage account name is available
    Write-Host "Checking storage account name availability..." -ForegroundColor Cyan
    $nameAvailability = Get-AzStorageAccountNameAvailability -Name $StorageAccountName
    if (-not $nameAvailability.NameAvailable) {
        throw "Storage account name '$StorageAccountName' is not available: $($nameAvailability.Reason)"
    }
    Write-Host "Storage account name is available" -ForegroundColor Green

    # Check if storage account already exists
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $storageAccount) {
        Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Yellow
        $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -SkuName "Standard_LRS" -Kind "StorageV2" -Tag $Tags
        Write-Host "Storage account created successfully" -ForegroundColor Green
    } else {
        Write-Host "Storage account already exists" -ForegroundColor Green
    }

    # Get storage context
    $storageContext = $storageAccount.Context

    # Check if container exists, create if not
    Write-Host "Checking container: $ContainerName" -ForegroundColor Cyan
    $container = Get-AzStorageContainer -Name $ContainerName -Context $storageContext -ErrorAction SilentlyContinue
    if (-not $container) {
        Write-Host "Creating container: $ContainerName" -ForegroundColor Yellow
        $container = New-AzStorageContainer -Name $ContainerName -Context $storageContext -Permission Off
        Write-Host "Container created successfully" -ForegroundColor Green
    } else {
        Write-Host "Container already exists" -ForegroundColor Green
    }

    # Generate SAS token for cross-tenant access (1 year expiry)
    Write-Host "Generating SAS token for cross-tenant access..." -ForegroundColor Cyan
    $sasStartTime = Get-Date
    $sasExpiryTime = $sasStartTime.AddYears(1)
    
    $sasToken = New-AzStorageContainerSASToken -Name $ContainerName -Context $storageContext -Permission "rl" -StartTime $sasStartTime -ExpiryTime $sasExpiryTime

    # Construct full SAS URL
    $sasUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName$sasToken"

    Write-Host "SAS token generated successfully" -ForegroundColor Green
    Write-Host "  Permissions: Read, List" -ForegroundColor White
    Write-Host "  Expires: $sasExpiryTime" -ForegroundColor White

    # Create summary information
    $setupSummary = @{
        ResourceGroupName = $ResourceGroupName
        StorageAccountName = $StorageAccountName
        ContainerName = $ContainerName
        Location = $Location
        StorageAccountUrl = "https://$StorageAccountName.blob.core.windows.net"
        ContainerUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName"
        SasToken = $sasToken
        SasUrl = $sasUrl
        SasExpiry = $sasExpiryTime
        CreatedDate = Get-Date
    }

    # Save configuration to file
    $configFile = "msp-storage-config.json"
    $setupSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $configFile -Encoding UTF8
    Write-Host "Configuration saved to: $configFile" -ForegroundColor Cyan

    # Create summary report
    $summaryFile = "msp-storage-summary.txt"
    $summary = @"
MSP Central Storage Setup Summary
================================
Setup Date: $(Get-Date)
Resource Group: $ResourceGroupName
Storage Account: $StorageAccountName
Container: $ContainerName
Location: $Location

Storage URLs:
- Storage Account: https://$StorageAccountName.blob.core.windows.net
- Container: https://$StorageAccountName.blob.core.windows.net/$ContainerName

SAS Token Information:
- Permissions: Read, List (cross-tenant access)
- Expires: $sasExpiryTime
- Token: $sasToken

Full SAS URL (for Guest Configuration policies):
$sasUrl

Next Steps:
1. Upload Guest Configuration packages to this container
2. Use the SAS URL in Guest Configuration Policy definitions
3. Deploy policies to customer tenants

Upload Command Example:
az storage blob upload --account-name $StorageAccountName --container-name $ContainerName --name "InstallDattoRMM.zip" --file ".\Packages\InstallDattoRMM.zip" --sas-token "$sasToken"

PowerShell Upload Example:
Set-AzStorageBlobContent -File ".\Packages\InstallDattoRMM.zip" -Container "$ContainerName" -Blob "InstallDattoRMM.zip" -Context `$storageContext

IMPORTANT: Keep the SAS token secure and rotate before expiry!

"@

    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host "Setup summary saved to: $summaryFile" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "=== Central Storage Setup Completed Successfully ===" -ForegroundColor Green
    Write-Host "Storage infrastructure ready for Guest Configuration packages" -ForegroundColor Green
    Write-Host ""
    Write-Host "SAS URL for policies:" -ForegroundColor Yellow
    Write-Host $sasUrl -ForegroundColor White

    # Return setup information
    return $setupSummary

} catch {
    Write-Host ""
    Write-Host "=== Storage Setup Failed ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host ""
    
    # Return error info
    return @{
        Success = $false
        Error = $_.Exception.Message
        Line = $_.InvocationInfo.ScriptLineNumber
    }
}
