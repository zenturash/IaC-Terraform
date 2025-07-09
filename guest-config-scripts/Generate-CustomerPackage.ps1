<#
.SYNOPSIS
    Interactive script to generate customer-specific Datto RMM Guest Configuration packages

.DESCRIPTION
    This script prompts for customer information and generates a customer-specific
    Guest Configuration package with hardcoded Site GUID for Datto RMM deployment.

.EXAMPLE
    .\Generate-CustomerPackage.ps1

.NOTES
    Author: MSP Automation Team
    Version: 1.0
    Creates customer-specific packages that work with Guest Configuration limitations
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "    Customer-Specific Datto RMM Package Generator" -ForegroundColor Magenta
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "This script generates a Guest Configuration package with hardcoded" -ForegroundColor Cyan
    Write-Host "Site GUID for a specific customer, bypassing runtime parameter limitations." -ForegroundColor Cyan
    Write-Host ""

    # Prompt for customer information
    do {
        $customerNumber = Read-Host "Enter Customer Number (4 digits)"
        if ($customerNumber -notmatch '^\d{4}$') {
            Write-Host "Invalid format. Please enter exactly 4 digits." -ForegroundColor Red
        }
    } while ($customerNumber -notmatch '^\d{4}$')

    do {
        $siteGuid = Read-Host "Enter Datto RMM Site GUID"
        if ($siteGuid -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
            Write-Host "Invalid GUID format. Please enter a valid GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)." -ForegroundColor Red
        }
    } while ($siteGuid -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')

    $defaultCustomerName = "Customer $customerNumber"
    $customerName = Read-Host "Enter Customer Name [$defaultCustomerName]"
    if ([string]::IsNullOrWhiteSpace($customerName)) {
        $customerName = $defaultCustomerName
    }

    Write-Host ""
    Write-Host "=== Customer Information ===" -ForegroundColor Yellow
    Write-Host "Customer Number: $customerNumber" -ForegroundColor White
    Write-Host "Site GUID: $siteGuid" -ForegroundColor White
    Write-Host "Customer Name: $customerName" -ForegroundColor White
    Write-Host ""

    $confirm = Read-Host "Generate package for this customer? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "=== Step 1: Compiling Customer-Specific MOF ===" -ForegroundColor Green

    # Create customer-specific output directory
    $customerOutputDir = ".\CustomerPackages\Customer-$customerNumber"
    if (-not (Test-Path $customerOutputDir)) {
        New-Item -ItemType Directory -Path $customerOutputDir -Force | Out-Null
        Write-Host "Created customer directory: $customerOutputDir" -ForegroundColor Cyan
    }

    # Check if DSC configuration file exists
    $dscConfigPath = ".\InstallDattoRMM-GuestConfig.ps1"
    if (-not (Test-Path $dscConfigPath)) {
        throw "DSC configuration file not found: $dscConfigPath"
    }

    # Load the DSC configuration
    Write-Host "Loading DSC configuration..." -ForegroundColor Cyan
    . $dscConfigPath

    # Compile the configuration with customer-specific parameters
    Write-Host "Compiling MOF with hardcoded customer values..." -ForegroundColor Cyan
    $compilationResult = InstallDattoRMM -SiteGuid $siteGuid -CustomerNumber $customerNumber -CustomerName $customerName -OutputPath $customerOutputDir

    # Verify MOF file was created
    $mofFile = Join-Path $customerOutputDir "localhost.mof"
    if (-not (Test-Path $mofFile)) {
        throw "MOF file was not created at expected location: $mofFile"
    }

    $mofInfo = Get-Item $mofFile
    Write-Host "✓ MOF compiled successfully: $($mofInfo.Length) bytes" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Step 2: Creating Customer-Specific Package ===" -ForegroundColor Green

    # Check for required modules
    Write-Host "Checking for GuestConfiguration module..." -ForegroundColor Cyan
    $guestConfigModule = Get-Module -Name "GuestConfiguration" -ListAvailable
    if (-not $guestConfigModule) {
        Write-Host "Installing GuestConfiguration module..." -ForegroundColor Yellow
        Install-Module -Name "GuestConfiguration" -Force -AllowClobber -Scope CurrentUser
    }

    Import-Module -Name "GuestConfiguration" -Force

    # Create customer-specific package
    $packageName = "InstallDattoRMM-$customerNumber"
    $packagePath = ".\Packages"
    
    if (-not (Test-Path $packagePath)) {
        New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    }

    Write-Host "Creating Guest Configuration package: $packageName" -ForegroundColor Cyan
    
    $packageParams = @{
        Name = $packageName
        Configuration = $mofFile
        Path = $packagePath
        Version = "1.0.0"
        Type = "AuditAndSet"
        Force = $true
    }

    $package = New-GuestConfigurationPackage @packageParams

    if (-not $package -or -not (Test-Path $package.Path)) {
        throw "Failed to create Guest Configuration package"
    }

    $packageInfo = Get-Item $package.Path
    Write-Host "✓ Package created: $($packageInfo.Name) ($($packageInfo.Length) bytes)" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Step 3: Generating Package Hash ===" -ForegroundColor Green

    $packageHash = Get-FileHash $package.Path -Algorithm SHA256
    Write-Host "✓ Package Hash: $($packageHash.Hash)" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Step 4: Upload to Storage (Optional) ===" -ForegroundColor Green

    $uploadChoice = Read-Host "Upload package to Azure Storage? (y/N)"
    $storageUrl = $null
    
    if ($uploadChoice -eq 'y' -or $uploadChoice -eq 'Y') {
        # Load storage configuration
        $storageConfigPath = ".\msp-storage-config.json"
        if (Test-Path $storageConfigPath) {
            $storageConfig = Get-Content $storageConfigPath | ConvertFrom-Json
            
            Write-Host "Uploading to storage account: $($storageConfig.StorageAccountName)" -ForegroundColor Cyan
            
            try {
                $blobName = "$packageName.zip"
                $uploadCommand = "az storage blob upload --account-name `"$($storageConfig.StorageAccountName)`" --container-name `"$($storageConfig.ContainerName)`" --name `"$blobName`" --file `"$($package.Path)`" --sas-token `"$($storageConfig.SasToken.TrimStart('?'))`" --overwrite"
                
                $uploadOutput = Invoke-Expression $uploadCommand 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $storageUrl = "$($storageConfig.ContainerUrl)/$blobName$($storageConfig.SasToken)"
                    Write-Host "✓ Package uploaded successfully" -ForegroundColor Green
                } else {
                    Write-Host "Upload failed: $uploadOutput" -ForegroundColor Red
                }
            } catch {
                Write-Host "Upload failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Storage configuration not found. Skipping upload." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "    Package Generation Completed Successfully!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""

    # Create summary
    $summary = @"
Customer-Specific Datto RMM Package Summary
==========================================
Generation Date: $(Get-Date)
Customer Number: $customerNumber
Customer Name: $customerName
Site GUID: $siteGuid

Package Details:
- Package Name: $packageName.zip
- Package Path: $($packageInfo.FullName)
- Package Size: $($packageInfo.Length) bytes
- Package Hash: $($packageHash.Hash)
- MOF File: $mofFile

"@

    if ($storageUrl) {
        $summary += @"
Storage Details:
- Storage URL: $storageUrl
- Ready for Guest Configuration deployment

"@
    }

    $summary += @"
Next Steps:
1. Use this package in Azure Guest Configuration assignment
2. Create manual assignment or policy pointing to this package
3. Deploy to customer VMs

Guest Configuration Settings:
- Configuration Name: InstallDattoRMM
- Type: Apply and monitor
- Content URI: $($storageUrl -or $packageInfo.FullName)
- Content Hash: $($packageHash.Hash)

Manual Assignment Command:
# Use the Create-ManualGuestConfigAssignment.ps1 script or
# Create assignment through Azure Portal with above settings

"@

    $summaryFile = ".\CustomerPackages\Customer-$customerNumber\package-summary.txt"
    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    
    # Also save as JSON for automation/configuration use
    $packageConfig = @{
        GenerationDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        CustomerNumber = $customerNumber
        CustomerName = $customerName
        SiteGuid = $siteGuid
        Package = @{
            Name = "$packageName.zip"
            Path = $packageInfo.FullName
            Size = $packageInfo.Length
            Hash = $packageHash.Hash
            Version = "1.0.0"
        }
        Configuration = @{
            Name = "InstallDattoRMM"
            Type = "AuditAndSet"
            MOFFile = $mofFile
        }
        Storage = if ($storageUrl) { @{
            URL = $storageUrl
            Uploaded = $true
        } } else { @{
            URL = $null
            Uploaded = $false
        } }
        Deployment = @{
            ContentURI = $storageUrl -or $packageInfo.FullName
            ContentHash = $packageHash.Hash
            ConfigurationName = "InstallDattoRMM"
            AssignmentType = "ApplyAndMonitor"
        }
    }
    
    $configFile = ".\CustomerPackages\Customer-$customerNumber\package-config.json"
    $packageConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8
    
    Write-Host $summary
    Write-Host "Summary saved to: $summaryFile" -ForegroundColor Cyan
    Write-Host "Configuration saved to: $configFile" -ForegroundColor Cyan

    return @{
        Success = $true
        CustomerNumber = $customerNumber
        SiteGuid = $siteGuid
        CustomerName = $customerName
        PackagePath = $packageInfo.FullName
        PackageHash = $packageHash.Hash
        StorageUrl = $storageUrl
        SummaryFile = $summaryFile
        ConfigFile = $configFile
        PackageConfig = $packageConfig
    }

} catch {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "    Package Generation Failed!" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    
    return @{
        Success = $false
        Error = $_.Exception.Message
    }
}
