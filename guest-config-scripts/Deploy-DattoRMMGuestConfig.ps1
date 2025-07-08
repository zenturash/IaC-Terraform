<#
.SYNOPSIS
    Master script to deploy Datto RMM Guest Configuration end-to-end

.DESCRIPTION
    This script orchestrates the complete deployment process for Datto RMM Guest Configuration:
    1. Sets up central storage in MSP tenant
    2. Compiles DSC configuration
    3. Creates Guest Configuration package
    4. Uploads package to storage
    5. Generates deployment summary

.PARAMETER StorageAccountName
    Name for the Azure Storage Account (must be globally unique)

.PARAMETER SiteGuid
    Datto RMM Site GUID for the initial package compilation

.PARAMETER CustomerName
    Customer name for the initial package

.PARAMETER SubscriptionId
    Azure subscription ID for your MSP tenant

.PARAMETER SkipStorageSetup
    Skip storage account setup if already exists

.EXAMPLE
    .\Deploy-DattoRMMGuestConfig.ps1 -StorageAccountName "mspguestconfig2025" -SiteGuid "ff01b552-a4cb-415e-b3c2-c6581a067479"

.NOTES
    Author: MSP Automation Team
    Version: 1.0
    This script must be run in your MSP tenant with appropriate permissions
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 24)]
    [ValidatePattern('^[a-z0-9]+$')]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SiteGuid,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomerName = "Initial Package",
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipStorageSetup
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Initialize deployment tracking
$deploymentStart = Get-Date
$deploymentLog = @()
$deploymentResults = @{}

function Write-DeploymentLog {
    param([string]$Message, [string]$Level = "Info")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor Cyan }
    }
    
    $script:deploymentLog += $logEntry
}

try {
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "    Datto RMM Guest Configuration Deployment" -ForegroundColor Magenta
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    Write-DeploymentLog "Starting Datto RMM Guest Configuration deployment"
    Write-DeploymentLog "Storage Account: $StorageAccountName"
    Write-DeploymentLog "Site GUID: $SiteGuid"
    Write-DeploymentLog "Customer: $CustomerName"
    Write-Host ""

    # Step 1: Setup Central Storage (if not skipped)
    if (-not $SkipStorageSetup) {
        Write-Host "=== Step 1: Setting Up Central Storage ===" -ForegroundColor Yellow
        Write-DeploymentLog "Setting up central storage infrastructure..."
        
        $storageParams = @{
            StorageAccountName = $StorageAccountName
        }
        if ($SubscriptionId) { $storageParams.SubscriptionId = $SubscriptionId }
        
        $storageResult = & "$PSScriptRoot\Setup-CentralStorage.ps1" @storageParams
        
        if ($storageResult.Success -eq $false) {
            throw "Storage setup failed: $($storageResult.Error)"
        }
        
        $deploymentResults.Storage = $storageResult
        Write-DeploymentLog "Central storage setup completed successfully" "Success"
        Write-DeploymentLog "SAS URL: $($storageResult.SasUrl)"
    } else {
        Write-DeploymentLog "Skipping storage setup as requested" "Warning"
        
        # Try to load existing storage config
        $configFile = "msp-storage-config.json"
        if (Test-Path $configFile) {
            $storageResult = Get-Content $configFile | ConvertFrom-Json
            $deploymentResults.Storage = $storageResult
            Write-DeploymentLog "Loaded existing storage configuration" "Success"
        } else {
            throw "Storage setup skipped but no existing configuration found. Run without -SkipStorageSetup first."
        }
    }
    
    Write-Host ""

    # Step 2: Compile DSC Configuration
    Write-Host "=== Step 2: Compiling DSC Configuration ===" -ForegroundColor Yellow
    Write-DeploymentLog "Compiling DSC configuration..."
    
    $compileResult = & "$PSScriptRoot\Compile-DattoRMMConfig.ps1" -SiteGuid $SiteGuid -CustomerName $CustomerName
    
    if ($compileResult.Success -eq $false) {
        throw "DSC compilation failed: $($compileResult.Error)"
    }
    
    $deploymentResults.Compilation = $compileResult
    Write-DeploymentLog "DSC compilation completed successfully" "Success"
    Write-DeploymentLog "MOF file: $($compileResult.MofFile)"
    Write-Host ""

    # Step 3: Create Guest Configuration Package
    Write-Host "=== Step 3: Creating Guest Configuration Package ===" -ForegroundColor Yellow
    Write-DeploymentLog "Creating Guest Configuration package..."
    
    $packageResult = & "$PSScriptRoot\Create-GuestConfigPackage.ps1" -MofPath $compileResult.OutputPath -Force
    
    if ($packageResult.Success -eq $false) {
        throw "Package creation failed: $($packageResult.Error)"
    }
    
    $deploymentResults.Package = $packageResult
    Write-DeploymentLog "Guest Configuration package created successfully" "Success"
    Write-DeploymentLog "Package file: $($packageResult.PackagePath)"
    Write-Host ""

    # Step 4: Upload Package to Storage
    Write-Host "=== Step 4: Uploading Package to Central Storage ===" -ForegroundColor Yellow
    Write-DeploymentLog "Uploading package to Azure Storage..."
    
    try {
        # Use Azure CLI for upload (more reliable)
        $uploadCommand = "az storage blob upload --account-name `"$($deploymentResults.Storage.StorageAccountName)`" --container-name `"$($deploymentResults.Storage.ContainerName)`" --name `"InstallDattoRMM.zip`" --file `"$($packageResult.PackagePath)`" --sas-token `"$($deploymentResults.Storage.SasToken.TrimStart('?'))`" --overwrite"
        
        Write-DeploymentLog "Executing upload command..."
        $uploadOutput = Invoke-Expression $uploadCommand 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-DeploymentLog "Package uploaded successfully" "Success"
            $deploymentResults.Upload = @{
                Success = $true
                BlobUrl = "$($deploymentResults.Storage.ContainerUrl)/InstallDattoRMM.zip"
                SasUrl = "$($deploymentResults.Storage.ContainerUrl)/InstallDattoRMM.zip$($deploymentResults.Storage.SasToken)"
            }
        } else {
            throw "Azure CLI upload failed: $uploadOutput"
        }
        
    } catch {
        Write-DeploymentLog "Azure CLI upload failed, trying PowerShell method..." "Warning"
        
        # Fallback to PowerShell upload
        try {
            Import-Module Az.Storage -Force
            $storageContext = New-AzStorageContext -StorageAccountName $deploymentResults.Storage.StorageAccountName -SasToken $deploymentResults.Storage.SasToken
            $blob = Set-AzStorageBlobContent -File $packageResult.PackagePath -Container $deploymentResults.Storage.ContainerName -Blob "InstallDattoRMM.zip" -Context $storageContext -Force
            
            Write-DeploymentLog "Package uploaded successfully via PowerShell" "Success"
            $deploymentResults.Upload = @{
                Success = $true
                BlobUrl = $blob.ICloudBlob.StorageUri.PrimaryUri
                SasUrl = "$($blob.ICloudBlob.StorageUri.PrimaryUri)$($deploymentResults.Storage.SasToken)"
            }
        } catch {
            throw "Both Azure CLI and PowerShell upload methods failed: $($_.Exception.Message)"
        }
    }
    
    Write-Host ""

    # Step 5: Generate Deployment Summary
    Write-Host "=== Step 5: Generating Deployment Summary ===" -ForegroundColor Yellow
    Write-DeploymentLog "Generating deployment summary..."
    
    $deploymentEnd = Get-Date
    $deploymentDuration = $deploymentEnd - $deploymentStart
    
    $summary = @"
Datto RMM Guest Configuration Deployment Summary
===============================================
Deployment Date: $deploymentStart
Deployment Duration: $($deploymentDuration.ToString("hh\:mm\:ss"))
Status: SUCCESS

=== Storage Infrastructure ===
Resource Group: $($deploymentResults.Storage.ResourceGroupName)
Storage Account: $($deploymentResults.Storage.StorageAccountName)
Container: $($deploymentResults.Storage.ContainerName)
Location: $($deploymentResults.Storage.Location)
SAS Expiry: $($deploymentResults.Storage.SasExpiry)

=== Package Information ===
Package Name: $($deploymentResults.Package.PackageName)
Package Version: $($deploymentResults.Package.PackageVersion)
Package Size: $($deploymentResults.Package.PackageSize) bytes
Local Path: $($deploymentResults.Package.PackagePath)

=== Upload Information ===
Blob URL: $($deploymentResults.Upload.BlobUrl)
SAS URL: $($deploymentResults.Upload.SasUrl)

=== DSC Configuration ===
Site GUID: $SiteGuid
Customer Name: $CustomerName
MOF File: $($deploymentResults.Compilation.MofFile)

=== Next Steps ===
1. Test the package by creating a Guest Configuration Policy
2. Deploy to customer tenants with their specific Site GUIDs
3. Monitor compliance through Azure Policy dashboard

=== Guest Configuration Policy Template ===
Use this SAS URL in your Guest Configuration Policy definitions:
$($deploymentResults.Upload.SasUrl)

=== Customer Deployment Example ===
For each customer tenant:
1. Create Guest Configuration Policy Definition
2. Assign policy with customer-specific parameters:
   {
     "SiteGuid": "customer-specific-site-guid",
     "CustomerName": "Customer Name"
   }

=== Monitoring ===
- Event Log Source: DattoRMM-DSC
- Azure Policy Compliance: Azure Portal > Policy > Compliance
- Package Access Logs: Storage Account > Monitoring > Logs

=== Security Notes ===
- SAS token expires: $($deploymentResults.Storage.SasExpiry)
- Permissions: Read, List only
- Scope: Container level access
- Rotate token before expiry!

"@

    $summaryFile = "deployment-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    
    # Also save deployment results as JSON
    $resultsFile = "deployment-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $deploymentResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsFile -Encoding UTF8
    
    Write-DeploymentLog "Deployment summary saved to: $summaryFile" "Success"
    Write-DeploymentLog "Deployment results saved to: $resultsFile" "Success"
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "    Deployment Completed Successfully!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "SAS URL for Guest Configuration Policies:" -ForegroundColor Yellow
    Write-Host $deploymentResults.Upload.SasUrl -ForegroundColor White
    Write-Host ""
    Write-Host "Summary file: $summaryFile" -ForegroundColor Cyan
    Write-Host "Results file: $resultsFile" -ForegroundColor Cyan
    
    return $deploymentResults

} catch {
    $deploymentEnd = Get-Date
    $deploymentDuration = $deploymentEnd - $deploymentStart
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "    Deployment Failed!" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    Write-DeploymentLog "Deployment failed: $($_.Exception.Message)" "Error"
    Write-DeploymentLog "Deployment duration: $($deploymentDuration.ToString("hh\:mm\:ss"))" "Error"
    
    # Save error log
    $errorLogFile = "deployment-error-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $errorLog = @"
Datto RMM Guest Configuration Deployment Error Log
=================================================
Deployment Date: $deploymentStart
Error Time: $deploymentEnd
Duration: $($deploymentDuration.ToString("hh\:mm\:ss"))

Error Details:
$($_.Exception.Message)

Stack Trace:
$($_.Exception.StackTrace)

Deployment Log:
$($deploymentLog -join "`n")

"@
    
    $errorLog | Out-File -FilePath $errorLogFile -Encoding UTF8
    Write-Host "Error log saved to: $errorLogFile" -ForegroundColor Red
    
    throw
}
