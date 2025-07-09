<#
.SYNOPSIS
    Creates Azure Guest Configuration package from compiled MOF files

.DESCRIPTION
    This script creates a Guest Configuration package (ZIP file) from the compiled
    Datto RMM DSC configuration, ready for upload to Azure Storage and deployment
    via Azure Policy Guest Configuration.

.PARAMETER MofPath
    Path to the directory containing the compiled MOF file

.PARAMETER PackageName
    Name for the Guest Configuration package (without .zip extension)

.PARAMETER PackageVersion
    Version for the Guest Configuration package

.PARAMETER OutputPath
    Path where the package ZIP file will be created

.PARAMETER Force
    Overwrite existing package if it exists

.EXAMPLE
    .\Create-GuestConfigPackage.ps1 -MofPath ".\Output" -PackageName "InstallDattoRMM" -PackageVersion "1.0.0"

.NOTES
    Author: MSP Automation Team
    Version: 1.0
    Requires: GuestConfiguration PowerShell module
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$MofPath,
    
    [Parameter(Mandatory = $false)]
    [string]$PackageName = "InstallDattoRMM",
    
    [Parameter(Mandatory = $false)]
    [string]$PackageVersion = "1.0.0",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Packages",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Azure Guest Configuration Package Creator ===" -ForegroundColor Green
    Write-Host "MOF Path: $MofPath" -ForegroundColor Yellow
    Write-Host "Package Name: $PackageName" -ForegroundColor Yellow
    Write-Host "Package Version: $PackageVersion" -ForegroundColor Yellow
    Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
    Write-Host ""

    # Check if GuestConfiguration module is available
    Write-Host "Checking for GuestConfiguration module..." -ForegroundColor Cyan
    $guestConfigModule = Get-Module -Name "GuestConfiguration" -ListAvailable
    if (-not $guestConfigModule) {
        Write-Host "GuestConfiguration module not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name "GuestConfiguration" -Force -AllowClobber -Scope CurrentUser
            Write-Host "GuestConfiguration module installed successfully" -ForegroundColor Green
        } catch {
            throw "Failed to install GuestConfiguration module: $($_.Exception.Message)"
        }
    } else {
        Write-Host "GuestConfiguration module found: Version $($guestConfigModule.Version)" -ForegroundColor Green
    }

    # Import the module
    Import-Module -Name "GuestConfiguration" -Force

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

    # Verify MOF file exists
    $mofFile = Join-Path $MofPath "localhost.mof"
    if (-not (Test-Path $mofFile)) {
        throw "MOF file not found: $mofFile. Please run Compile-DattoRMMConfig.ps1 first."
    }

    Write-Host "Found MOF file: $mofFile" -ForegroundColor Green

    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        Write-Host "Creating output directory: $OutputPath" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    # Check if package already exists
    $packagePath = Join-Path $OutputPath "$PackageName.zip"
    if ((Test-Path $packagePath) -and -not $Force) {
        throw "Package already exists: $packagePath. Use -Force to overwrite."
    }

    # Remove existing package if Force is specified
    if ((Test-Path $packagePath) -and $Force) {
        Write-Host "Removing existing package..." -ForegroundColor Yellow
        Remove-Item $packagePath -Force
    }

    # Create Guest Configuration package
    Write-Host "Creating Guest Configuration package..." -ForegroundColor Cyan
    
    # Prepare package parameters including Type
    $packageParams = @{
        Name = $PackageName
        Configuration = $mofFile
        Path = $OutputPath
        Version = $PackageVersion
        Force = $Force.IsPresent
        Type = "AuditAndSet"
    }

    # Create the package with AuditAndSet type (applies configuration)
    Write-Host "Creating package with Type: AuditAndSet" -ForegroundColor Yellow
    $package = New-GuestConfigurationPackage @packageParams

    if (-not $package) {
        throw "Failed to create Guest Configuration package"
    }

    # Verify package was created
    if (-not (Test-Path $package.Path)) {
        throw "Package file not found after creation: $($package.Path)"
    }

    # Get package info
    $packageInfo = Get-Item $package.Path
    Write-Host "Package created successfully:" -ForegroundColor Green
    Write-Host "  Path: $($packageInfo.FullName)" -ForegroundColor White
    Write-Host "  Size: $($packageInfo.Length) bytes" -ForegroundColor White
    Write-Host "  Created: $($packageInfo.CreationTime)" -ForegroundColor White

    # Validate package contents
    Write-Host "Validating package contents..." -ForegroundColor Cyan
    
    # Extract and examine package contents
    $tempExtractPath = Join-Path $env:TEMP "GuestConfigValidation_$(Get-Random)"
    try {
        # Create temp directory
        New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null
        
        # Extract ZIP
        Expand-Archive -Path $package.Path -DestinationPath $tempExtractPath -Force
        
        # Check for required files (Guest Configuration packages have different structure)
        $requiredFiles = @("Modules")
        $validationPassed = $true
        
        # Check for Modules directory
        $modulesPath = Join-Path $tempExtractPath "Modules"
        if (Test-Path $modulesPath) {
            Write-Host "  ✓ Modules directory found in package" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Modules directory NOT found in package" -ForegroundColor Red
            $validationPassed = $false
        }
        
        # Check for MOF file (it might be named differently in Guest Configuration packages)
        $mofFiles = Get-ChildItem -Path $tempExtractPath -Filter "*.mof" -Recurse
        if ($mofFiles.Count -gt 0) {
            Write-Host "  ✓ MOF file(s) found in package: $($mofFiles.Name -join ', ')" -ForegroundColor Green
            
            # Check MOF content for Datto RMM URL
            $mofContent = Get-Content $mofFiles[0].FullName -Raw
            if ($mofContent -match "merlot\.rmm\.datto\.com") {
                Write-Host "  ✓ Datto RMM URL found in MOF content" -ForegroundColor Green
            } else {
                Write-Host "  ✗ Datto RMM URL NOT found in MOF content" -ForegroundColor Red
                $validationPassed = $false
            }
        } else {
            Write-Host "  ✗ No MOF files found in package" -ForegroundColor Red
            $validationPassed = $false
        }
        
        # Check for PSDscResources module
        $psDscResourcesPath = Join-Path $modulesPath "PSDscResources"
        if (Test-Path $psDscResourcesPath) {
            Write-Host "  ✓ PSDscResources module found in package" -ForegroundColor Green
        } else {
            Write-Host "  - PSDscResources module not found (may be included differently)" -ForegroundColor Yellow
        }
        
    } finally {
        # Cleanup temp directory
        if (Test-Path $tempExtractPath) {
            Remove-Item $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not $validationPassed) {
        throw "Package validation failed - required contents missing"
    }

    # Create package summary
    $summaryFile = Join-Path $OutputPath "$PackageName-package-summary.txt"
    $summary = @"
Datto RMM Guest Configuration Package Summary
============================================
Creation Date: $(Get-Date)
Package Name: $PackageName
Package Version: $PackageVersion
Package Path: $($packageInfo.FullName)
Package Size: $($packageInfo.Length) bytes
Source MOF: $mofFile
Validation: PASSED

Package Contents:
- localhost.mof (DSC configuration)
- Modules/ (PowerShell DSC modules)

Next Steps:
1. Upload package to Azure Storage Account
2. Generate SAS token for cross-tenant access
3. Create Guest Configuration Policy Definition
4. Test policy assignment on target VMs

Upload Command Example:
az storage blob upload --account-name <storage-account> --container-name <container> --name $PackageName.zip --file "$($packageInfo.FullName)"

"@

    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host "Package summary saved to: $summaryFile" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "=== Package Creation Completed Successfully ===" -ForegroundColor Green
    Write-Host "Guest Configuration package ready for upload to Azure Storage" -ForegroundColor Green

    # Return package info
    return @{
        Success = $true
        PackagePath = $packageInfo.FullName
        PackageName = $PackageName
        PackageVersion = $PackageVersion
        PackageSize = $packageInfo.Length
        SummaryFile = $summaryFile
        UploadReady = $true
    }

} catch {
    Write-Host ""
    Write-Host "=== Package Creation Failed ===" -ForegroundColor Red
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
