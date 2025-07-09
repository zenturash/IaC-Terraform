<#
.SYNOPSIS
    Compiles the Datto RMM DSC configuration for Guest Configuration (without hardcoded parameters)

.DESCRIPTION
    This script compiles the InstallDattoRMM DSC configuration WITHOUT parameters
    to create a template MOF file that can accept parameters at runtime via Guest Configuration.

.PARAMETER OutputPath
    Path where the compiled MOF files will be saved

.EXAMPLE
    .\Compile-DattoRMM-GuestConfig.ps1 -OutputPath "C:\DSC\Output"

.NOTES
    Author: MSP Automation Team
    Version: 2.0
    This creates a parameterized MOF for Guest Configuration
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Output"
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Datto RMM Guest Configuration Compiler ===" -ForegroundColor Green
    Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
    Write-Host "Mode: Guest Configuration (Parameterized)" -ForegroundColor Yellow
    Write-Host ""

    # Check if DSC configuration file exists
    $dscConfigPath = Join-Path $PSScriptRoot "InstallDattoRMM-GuestConfig.ps1"
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
    Write-Host "Loading Guest Configuration DSC..." -ForegroundColor Cyan
    . $dscConfigPath

    # Verify the configuration function is loaded
    if (-not (Get-Command -Name "InstallDattoRMM" -ErrorAction SilentlyContinue)) {
        throw "InstallDattoRMM configuration function not found after loading the script"
    }

    # Compile the configuration WITHOUT parameters (for Guest Configuration)
    Write-Host "Compiling DSC configuration for Guest Configuration..." -ForegroundColor Cyan
    $compilationResult = InstallDattoRMM -OutputPath $OutputPath

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

    # Validate MOF content for Guest Configuration
    Write-Host "Validating MOF content for Guest Configuration..." -ForegroundColor Cyan
    $mofContent = Get-Content $mofFile -Raw
    
    # Check for required elements (should NOT contain hardcoded values)
    $validationChecks = @(
        @{ Name = "Script Resource"; Pattern = "MSFT_ScriptResource"; Required = $true },
        @{ Name = "Configuration Name"; Pattern = "InstallDattoRMM"; Required = $true },
        @{ Name = "No Hardcoded GUID"; Pattern = "ff01b552-a4cb-415e-b3c2-c6581a067479"; Required = $false; ShouldNotExist = $true }
    )

    $validationPassed = $true
    foreach ($check in $validationChecks) {
        if ($check.ShouldNotExist) {
            if ($mofContent -match $check.Pattern) {
                Write-Host "  ✗ $($check.Name) found in MOF (should not exist for Guest Configuration)" -ForegroundColor Red
                $validationPassed = $false
            } else {
                Write-Host "  ✓ $($check.Name) correctly absent from MOF" -ForegroundColor Green
            }
        } else {
            if ($mofContent -match $check.Pattern) {
                Write-Host "  ✓ $($check.Name) found in MOF" -ForegroundColor Green
            } elseif ($check.Required) {
                Write-Host "  ✗ $($check.Name) NOT found in MOF" -ForegroundColor Red
                $validationPassed = $false
            } else {
                Write-Host "  - $($check.Name) not found (optional)" -ForegroundColor Yellow
            }
        }
    }

    if (-not $validationPassed) {
        throw "MOF validation failed - Guest Configuration requirements not met"
    }

    # Create a summary file
    $summaryFile = Join-Path $OutputPath "guest-config-compilation-summary.txt"
    $summary = @"
Datto RMM Guest Configuration Compilation Summary
===============================================
Compilation Date: $(Get-Date)
Compilation Mode: Guest Configuration (Parameterized)
MOF File: $($mofInfo.FullName)
MOF Size: $($mofInfo.Length) bytes
Validation: PASSED

Guest Configuration Features:
- No hardcoded Site GUID (parameters passed at runtime)
- Compatible with Azure Guest Configuration parameter injection
- Ready for multi-tenant deployment

Next Steps:
1. Create Guest Configuration package using New-GuestConfigurationPackage
2. Upload package to Azure Storage Account
3. Use this package with Guest Configuration policies
4. Parameters will be injected at runtime via configurationParameter

"@

    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host "Compilation summary saved to: $summaryFile" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "=== Guest Configuration Compilation Completed Successfully ===" -ForegroundColor Green
    Write-Host "MOF file ready for Guest Configuration packaging (parameterized)" -ForegroundColor Green

    # Return compilation info
    return @{
        Success = $true
        MofFile = $mofInfo.FullName
        OutputPath = $OutputPath
        SummaryFile = $summaryFile
        Mode = "GuestConfiguration"
        Parameterized = $true
    }

} catch {
    Write-Host ""
    Write-Host "=== Guest Configuration Compilation Failed ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host ""
    
    # Return error info
    return @{
        Success = $false
        Error = $_.Exception.Message
        Line = $_.InvocationInfo.ScriptLineNumber
        Mode = "GuestConfiguration"
    }
}
