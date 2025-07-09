<#
.SYNOPSIS
    Creates a manual Guest Configuration assignment with parameters via PowerShell

.DESCRIPTION
    This script creates a Guest Configuration assignment directly on a VM with 
    the required parameters (SiteGuid and CustomerName) that cannot be set 
    through the Azure Portal interface.

.PARAMETER VMName
    Name of the target virtual machine

.PARAMETER ResourceGroupName
    Resource group containing the VM

.PARAMETER SiteGuid
    Datto RMM Site GUID

.PARAMETER CustomerName
    Customer name for logging

.EXAMPLE
    .\Create-ManualGuestConfigAssignment.ps1 -VMName "AVD-JUMP-0" -ResourceGroupName "RG_AVD_JUMPHOST" -SiteGuid "ff01b552-a4cb-415e-b3c2-c6581a067479" -CustomerName "Test Customer"

.NOTES
    Author: MSP Automation Team
    Version: 1.0
    This bypasses the Azure Portal limitation for parameterized Guest Configurations
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SiteGuid,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomerName = "Default Customer",
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Manual Guest Configuration Assignment Creator ===" -ForegroundColor Green
    Write-Host "VM Name: $VMName" -ForegroundColor Yellow
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
    Write-Host "Site GUID: $SiteGuid" -ForegroundColor Yellow
    Write-Host "Customer Name: $CustomerName" -ForegroundColor Yellow
    Write-Host ""

    # Check if Azure PowerShell module is available
    Write-Host "Checking for Azure PowerShell module..." -ForegroundColor Cyan
    $azModule = Get-Module -Name "Az.Accounts" -ListAvailable
    if (-not $azModule) {
        Write-Host "Azure PowerShell module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name "Az" -Force -AllowClobber -Scope CurrentUser
        Write-Host "Azure PowerShell module installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Azure PowerShell module found: Version $($azModule.Version)" -ForegroundColor Green
    }

    # Import required modules
    Import-Module -Name "Az.Accounts" -Force
    Import-Module -Name "Az.Resources" -Force

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

    # Set subscription if specified
    if ($SubscriptionId) {
        Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Cyan
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    # Verify VM exists
    Write-Host "Verifying VM exists..." -ForegroundColor Cyan
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction SilentlyContinue
    if (-not $vm) {
        throw "VM '$VMName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "VM found: $($vm.Name) in $($vm.Location)" -ForegroundColor Green

    # Configuration details
    $configurationName = "InstallDattoRMM"
    $contentUri = "https://zenturamspguestconfig.blob.core.windows.net/guest-configurations/InstallDattoRMM.zip?sp=rl&st=2025-07-08T14:33:32Z&se=2035-08-09T22:33:32Z&spr=https&sv=2024-11-04&sr=c&sig=rvcknUpe7QAkUOGYTHh6aKMrYNK0ujOMQacz19Osc24%3D"
    $contentHash = "6FE1D5F3ACFD867CF34CF3503FCEE9D37CD1A3E0CE2EB9CF20600794D28194C6"

    # Create Guest Configuration assignment using REST API
    Write-Host "Creating Guest Configuration assignment..." -ForegroundColor Cyan
    
    $assignmentBody = @{
        properties = @{
            guestConfiguration = @{
                name = $configurationName
                version = "1.0.0"
                assignmentType = "ApplyAndMonitor"
                contentUri = $contentUri
                contentHash = $contentHash
                configurationParameter = @(
                    @{
                        name = "$configurationName;SiteGuid"
                        value = $SiteGuid
                    },
                    @{
                        name = "$configurationName;CustomerName"
                        value = $CustomerName
                    }
                )
                configurationSetting = @{
                    configurationMode = "ApplyAndMonitor"
                    allowModuleOverwrite = $true
                    actionAfterReboot = "ContinueConfiguration"
                    refreshFrequencyMins = 30
                    rebootIfNeeded = $true
                    configurationModeFrequencyMins = 15
                }
            }
        }
    } | ConvertTo-Json -Depth 10

    # Get access token
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com/").AccessToken

    # REST API call
    $resourceId = "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$VMName/providers/Microsoft.GuestConfiguration/guestConfigurationAssignments/$configurationName"
    $uri = "https://management.azure.com$resourceId" + "?api-version=2020-06-25"
    
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }

    Write-Host "Making REST API call to create assignment..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $uri -Method PUT -Body $assignmentBody -Headers $headers

    Write-Host "Guest Configuration assignment created successfully!" -ForegroundColor Green
    Write-Host "Assignment Name: $configurationName" -ForegroundColor White
    Write-Host "Assignment Type: ApplyAndMonitor" -ForegroundColor White
    Write-Host "Parameters:" -ForegroundColor White
    Write-Host "  SiteGuid: $SiteGuid" -ForegroundColor White
    Write-Host "  CustomerName: $CustomerName" -ForegroundColor White

    # Create summary
    $summary = @"
Manual Guest Configuration Assignment Summary
===========================================
Creation Date: $(Get-Date)
VM Name: $VMName
Resource Group: $ResourceGroupName
Configuration Name: $configurationName
Assignment Type: ApplyAndMonitor

Parameters:
- SiteGuid: $SiteGuid
- CustomerName: $CustomerName

Configuration Details:
- Content URI: $contentUri
- Content Hash: $contentHash
- Version: 1.0.0

Next Steps:
1. Monitor the assignment status in Azure Portal
2. Check VM for Guest Configuration extension installation
3. Verify Datto RMM agent installation
4. Check event logs for installation progress

Monitoring Commands:
# Check assignment status
Get-AzVMGuestConfigurationAssignment -ResourceGroupName "$ResourceGroupName" -VMName "$VMName"

# Check compliance
Get-AzVMGuestConfigurationAssignmentReport -ResourceGroupName "$ResourceGroupName" -VMName "$VMName" -GuestConfigurationAssignmentName "$configurationName"

"@

    $summaryFile = "manual-guest-config-assignment-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host "Assignment summary saved to: $summaryFile" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "=== Assignment Creation Completed Successfully ===" -ForegroundColor Green
    Write-Host "Guest Configuration will now apply to the VM with your specified parameters" -ForegroundColor Green

    return @{
        Success = $true
        VMName = $VMName
        ResourceGroupName = $ResourceGroupName
        ConfigurationName = $configurationName
        SiteGuid = $SiteGuid
        CustomerName = $CustomerName
        SummaryFile = $summaryFile
    }

} catch {
    Write-Host ""
    Write-Host "=== Assignment Creation Failed ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    
    return @{
        Success = $false
        Error = $_.Exception.Message
    }
}
