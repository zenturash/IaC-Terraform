<#
.SYNOPSIS
    DSC Configuration for installing Datto RMM agent via Azure Guest Configuration

.DESCRIPTION
    This PowerShell DSC configuration installs the Datto RMM agent on Windows machines
    using Guest Configuration parameters for multi-tenant MSP deployments.

.NOTES
    Author: MSP Automation Team
    Version: 2.0
    Created for Azure Guest Configuration deployment
    
    For Guest Configuration, parameters are passed via configurationParameter in the policy,
    not as DSC configuration parameters.
#>

Configuration InstallDattoRMM {
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$SiteGuid,
        
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d{4}$')]
        [string]$CustomerNumber,
        
        [Parameter(Mandatory = $false)]
        [string]$CustomerName = "Customer"
    )
    
    Import-DscResource -ModuleName PSDscResources
    
    Node localhost {
        
        # Create event log source for Datto RMM installation tracking
        Script CreateEventLogSource {
            GetScript = {
                $logExists = [System.Diagnostics.EventLog]::SourceExists("DattoRMM-DSC")
                return @{ Result = $logExists }
            }
            
            SetScript = {
                try {
                    New-EventLog -LogName Application -Source "DattoRMM-DSC" -ErrorAction SilentlyContinue
                    Write-EventLog -LogName Application -Source "DattoRMM-DSC" -EventId 1000 -Message "DattoRMM DSC event log source created"
                } catch {
                    # Event source might already exist, continue
                }
            }
            
            TestScript = {
                return [System.Diagnostics.EventLog]::SourceExists("DattoRMM-DSC")
            }
        }
        
        # Main Datto RMM installation script
        Script InstallDattoRMM {
            GetScript = {
                # Check if Datto RMM is installed
                # Look for the specific CagService (Datto RMM service)
                $dattoService = Get-Service -Name "CagService" -ErrorAction SilentlyContinue
                $dattoProcess = Get-Process -Name "CagService" -ErrorAction SilentlyContinue
                
                # Safely check registry for Datto RMM installation
                $dattoRegistry = $null
                try {
                    $dattoRegistry = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { 
                        $_.DisplayName -and $_.DisplayName -like "*Datto*" 
                    }
                } catch {
                    # Registry check failed, continue without it
                }
                
                $installed = $false
                if ($dattoService -or $dattoProcess -or $dattoRegistry) {
                    $installed = $true
                }
                
                return @{ 
                    Result = if ($installed) { "Installed" } else { "Not Installed" }
                }
            }
            
            SetScript = {
                # Get hardcoded parameters from compilation time
                $siteGuid = $using:SiteGuid
                $customerNumber = $using:CustomerNumber
                $customerName = $using:CustomerName
                
                $url = "https://merlot.rmm.datto.com/download-agent/windows/$siteGuid"
                $dest = "$env:TEMP\DattoRMMInstaller_$customerNumber.exe"
                $logSource = "DattoRMM-DSC"
                
                try {
                    Write-EventLog -LogName Application -Source $logSource -EventId 1001 -Message "Starting Datto RMM installation for customer: $customerName, Site GUID: $siteGuid"
                    
                    # Download the installer
                    Write-EventLog -LogName Application -Source $logSource -EventId 1002 -Message "Downloading Datto RMM installer from: $url"
                    
                    # Use TLS 1.2 for secure download
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    
                    $webClient = New-Object System.Net.WebClient
                    $webClient.Headers.Add("User-Agent", "DattoRMM-DSC-Installer/2.0")
                    $webClient.DownloadFile($url, $dest)
                    
                    # Verify download
                    if (-not (Test-Path $dest)) {
                        throw "Downloaded file not found at: $dest"
                    }
                    
                    $fileSize = (Get-Item $dest).Length
                    if ($fileSize -lt 1MB) {
                        throw "Downloaded file appears to be too small (${fileSize} bytes), possibly an error page"
                    }
                    
                    Write-EventLog -LogName Application -Source $logSource -EventId 1003 -Message "Download completed successfully. File size: $fileSize bytes"
                    
                    # Install the agent
                    Write-EventLog -LogName Application -Source $logSource -EventId 1004 -Message "Starting Datto RMM agent installation"
                    
                    $installProcess = Start-Process -FilePath $dest -ArgumentList "/S" -Wait -PassThru -NoNewWindow
                    
                    if ($installProcess.ExitCode -eq 0) {
                        Write-EventLog -LogName Application -Source $logSource -EventId 1005 -Message "Datto RMM agent installation completed successfully"
                        
                        # Wait for services to start
                        Start-Sleep -Seconds 30
                        
                        # Verify installation
                        $service = Get-Service -Name "*Datto*" -ErrorAction SilentlyContinue
                        if ($service) {
                            Write-EventLog -LogName Application -Source $logSource -EventId 1006 -Message "Datto RMM service detected: $($service.Name) - Status: $($service.Status)"
                        }
                    } else {
                        throw "Installation failed with exit code: $($installProcess.ExitCode)"
                    }
                    
                } catch {
                    $errorMessage = "Datto RMM installation failed: $($_.Exception.Message)"
                    Write-EventLog -LogName Application -Source $logSource -EventId 1999 -EntryType Error -Message $errorMessage
                    throw $errorMessage
                } finally {
                    # Cleanup installer file
                    if (Test-Path $dest) {
                        Remove-Item $dest -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            
            TestScript = {
                # Check if Datto RMM is properly installed and running
                # Look for the specific CagService (Datto RMM service)
                $dattoService = Get-Service -Name "CagService" -ErrorAction SilentlyContinue
                $dattoProcess = Get-Process -Name "CagService" -ErrorAction SilentlyContinue
                
                # Safely check registry for Datto RMM installation
                $dattoRegistry = $null
                try {
                    $dattoRegistry = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { 
                        $_.DisplayName -and $_.DisplayName -like "*Datto*" 
                    }
                } catch {
                    # Registry check failed, continue without it
                }
                
                # Consider it installed if we have either a service, process, or registry entry
                $isInstalled = ($dattoService -ne $null) -or ($dattoProcess -ne $null) -or ($dattoRegistry -ne $null)
                
                if ($isInstalled) {
                    try {
                        $siteGuid = $using:SiteGuid
                        $customerNumber = $using:CustomerNumber
                        Write-EventLog -LogName Application -Source "DattoRMM-DSC" -EventId 1007 -Message "Datto RMM agent validation successful for Customer $customerNumber, Site GUID: $siteGuid"
                    } catch {
                        # Event log might not be available, continue
                    }
                }
                
                return $isInstalled
            }
            
            DependsOn = "[Script]CreateEventLogSource"
        }
    }
}
