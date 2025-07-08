<#
.SYNOPSIS
    Compiles the Datto RMM DSC configuration into MOF files for Guest Configuration

.DESCRIPTION
    This script compiles the InstallDattoRMM DSC configuration with different Site GUIDs
    to create MOF files that can be packaged for Azure Guest Configuration deployment.

.PARAMETER SiteGuid
    The Datto RMM Site GUID for the specific customer/tenant

.PARAMETER CustomerName
    Optional customer name for identification

.PARAMETER OutputPath
    Path where the compiled MOF files will be saved

.EXAMPLE
    .\Compile-DattoRMMConfig.ps1 -SiteGuid "ff01b552-a4cb-415e-b3c2-c6581a067479" -CustomerName "Customer A" -OutputPath "C:\DSC\Output"

.NOTES
    Author: MSP Automation Team
    Version: 1.0
    Requires: PowerShell 5.1 or later with DSC support
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SiteGuid,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomerName = "Default Customer",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Output"
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Datto RMM DSC Configuration Compiler ===" -ForegroundColor Green
    Write-Host "Site GUID: $SiteGuid" -ForegroundColor Yellow
    Write-Host "Customer: $CustomerName" -ForegroundColor Yellow
    Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
    Write-Host ""

    # Check if DSC configuration file exists
    $dscConfigPath = Join-Path $PSScriptRoot "InstallDattoRMM.ps1"
    if (-not (Test-Path $dscConfigPath)) {
        throw "DSC configuration file not found: $dscConfigPath"
    }

    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        Write-Host "Creating output directory: $OutputPath" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    # Clean existing MOF files in output directory
    $existingMofs = Get-ChildItem -Path $OutputPath -Filter "*.mof" -ErrorAction SilentlyContinue
    if ($existingMofs) {
        Write-Host "Cleaning existing MOF files..." -ForegroundColor Cyan
        $existingMofs | Remove-Item -Force
    }

    # Check if PSDscResources module is available (required for Guest Configuration)
    Write-Host "Checking for PSDscResources module..." -ForegroundColor Cyan
    $psDscModule = Get-Module -Name "PSDscResources" -ListAvailable
    if (-not $psDscModule) {
        Write-Host "PSDscResources module not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name "PSDscResources" -Force -AllowClobber -Scope CurrentUser
            Write-Host "PSDscResources module installed successfully" -ForegroundColor Green
        } catch {
            throw "Failed to install PSDscResources module: $($_.Exception.Message)"
        }
    } else {
        Write-Host "PSDscResources module found: Version $($psDscModule.Version)" -ForegroundColor Green
    }

    # Load the DSC configuration
    Write-Host "Loading DSC configuration..." -ForegroundColor Cyan
    . $dscConfigPath

    # Verify the configuration function is loaded
    if (-not (Get-Command -Name "InstallDattoRMM" -ErrorAction SilentlyContinue)) {
        throw "InstallDattoRMM configuration function not found after loading the script"
    }

    # Compile the configuration
    Write-Host "Compiling DSC configuration..." -ForegroundColor Cyan
    $compilationResult = InstallDattoRMM -SiteGuid $SiteGuid -CustomerName $CustomerName -OutputPath $OutputPath

    # Verify MOF file was created
    $mofFile = Join-Path $OutputPath "localhost.mof"
    if (-not (Test-Path $mofFile)) {
        throw "MOF file was not created at expected location: $mofFile"
    }

    # Get MOF file info
    $mofInfo = Get-Item $mofFile
    Write-Host "MOF file created successfully:" -ForegroundColor Green
    Write-Host "  Path: $($mofInfo.FullName)" -ForegroundColor White
    Write-Host "  Size: $($mofInfo.Length) bytes" -ForegroundColor White
    Write-Host "  Created: $($mofInfo.CreationTime)" -ForegroundColor White

    # Validate MOF content
    Write-Host "Validating MOF content..." -ForegroundColor Cyan
    $mofContent = Get-Content $mofFile -Raw
    
    # Check for required elements
    $validationChecks = @(
        @{ Name = "Site GUID"; Pattern = $SiteGuid; Required = $true },
        @{ Name = "Customer Name"; Pattern = $CustomerName; Required = $false },
        @{ Name = "Download URL"; Pattern = "merlot\.rmm\.datto\.com"; Required = $true },
        @{ Name = "Script Resource"; Pattern = "MSFT_ScriptResource"; Required = $true }
    )

    $validationPassed = $true
    foreach ($check in $validationChecks) {
        if ($mofContent -match $check.Pattern) {
            Write-Host "  ✓ $($check.Name) found in MOF" -ForegroundColor Green
        } elseif ($check.Required) {
            Write-Host "  ✗ $($check.Name) NOT found in MOF" -ForegroundColor Red
            $validationPassed = $false
        } else {
            Write-Host "  - $($check.Name) not found (optional)" -ForegroundColor Yellow
        }
    }

    if (-not $validationPassed) {
        throw "MOF validation failed - required elements missing"
    }

    # Create a summary file
    $summaryFile = Join-Path $OutputPath "compilation-summary.txt"
    $summary = @"
Datto RMM DSC Compilation Summary
================================
Compilation Date: $(Get-Date)
Site GUID: $SiteGuid
Customer Name: $CustomerName
MOF File: $($mofInfo.FullName)
MOF Size: $($mofInfo.Length) bytes
Validation: PASSED

Next Steps:
1. Create Guest Configuration package using New-GuestConfigurationPackage
2. Upload package to Azure Storage Account
3. Generate SAS token for cross-tenant access
4. Create Guest Configuration Policy Definition
5. Assign policy to target subscriptions/VMs

"@

    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host "Compilation summary saved to: $summaryFile" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "=== Compilation Completed Successfully ===" -ForegroundColor Green
    Write-Host "MOF file ready for Guest Configuration packaging" -ForegroundColor Green

    # Return compilation info
    return @{
        Success = $true
        MofFile = $mofInfo.FullName
        SiteGuid = $SiteGuid
        CustomerName = $CustomerName
        OutputPath = $OutputPath
        SummaryFile = $summaryFile
    }

} catch {
    Write-Host ""
    Write-Host "=== Compilation Failed ===" -ForegroundColor Red
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
