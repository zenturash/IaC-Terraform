# Azure Policy Initiative - Datto RMM Agent Complete Solution

This OpenTofu module creates and deploys a comprehensive Azure Policy Initiative that automatically installs the Datto RMM agent on Windows virtual machines using Azure Guest Configuration.

## Features

- **Policy Initiative**: Single deployment unit containing both prerequisite and main policies
- **Guest Configuration Extension**: Automatically installs required Guest Configuration extension
- **Automatic Installation**: Uses `ApplyAndMonitor` mode to install Datto RMM agent
- **Subscription-Level Enforcement**: Applies initiative at subscription scope
- **Managed Identity**: Creates system-assigned identity with required permissions
- **Automatic Remediation**: Remediates existing non-compliant VMs immediately
- **Parameterized Site GUID**: Configurable Datto RMM site identifier
- **Content Hash Validation**: Secure package validation using SHA256 hash

## Architecture

The initiative deploys two coordinated policies:

1. **Guest Configuration Extension Prerequisite** - Installs Guest Configuration extension on Windows VMs
2. **Datto RMM Installation** - Deploys Datto RMM agent via Guest Configuration

```
Policy Initiative: "Datto RMM Complete Solution"
├── Policy 1: Guest Configuration Extension Prerequisite
│   ├── Installs: Microsoft.GuestConfiguration/ConfigurationforWindows
│   └── Role: Virtual Machine Contributor
└── Policy 2: Datto RMM Guest Configuration Installation
    ├── Deploys: Guest Configuration Assignment
    ├── Package: InstallDattoRMM.zip (from your storage account)
    ├── Mode: ApplyAndMonitor (actually installs software)
    └── Roles: Guest Configuration Resource Contributor + VM Contributor
```

## DSC Configuration

The initiative uses **ApplyAndMonitor mode** with your existing DSC configuration that:

```powershell
# Downloads and installs Datto RMM agent
$url = "https://merlot.rmm.datto.com/download-agent/windows/$SiteGuid"
$dest = "$env:TEMP\DattoRMMInstaller_$siteGuid.exe"
(New-Object System.Net.WebClient).DownloadFile($url, $dest)
Start-Process $dest -ArgumentList "/S" -Wait
```

### Configuration Settings:
- **Configuration Mode**: `ApplyAndMonitor` (installs and monitors)
- **Refresh Frequency**: 30 minutes
- **Configuration Frequency**: 15 minutes
- **Reboot If Needed**: Enabled
- **Module Overwrite**: Allowed

## Usage

### Basic Usage

```hcl
module "datto_rmm_initiative" {
  source = "./modules/azure-policy-datto-rmm"

  # Required variables
  site_guid       = "d5792943-c2e4-40b3-84b8-dccac61f4d35"  # Your Datto RMM site GUID
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  location        = "West Europe"

  # Optional customization
  policy_name             = "deploy-datto-rmm-complete"
  assignment_name         = "assign-datto-rmm-complete"
  customer_name           = "Customer Name"
  create_remediation_task = true

  tags = {
    environment = "production"
    component   = "monitoring"
  }
}
```

### Integration with Main OpenTofu Project

The module is automatically integrated when you enable it in your main configuration:

```hcl
# In terraform.tfvars
deploy_components = {
  vpn_gateway  = true
  vms          = true
  peering      = true
  datto_policy = true  # Enable Datto RMM initiative
}

datto_rmm_config = {
  enabled   = true
  site_guid = "d5792943-c2e4-40b3-84b8-dccac61f4d35"  # Your actual site GUID
}

customer_config = {
  customer_name = "Your Customer Name"
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `site_guid` | `string` | Datto RMM site GUID for agent installation |
| `subscription_id` | `string` | Azure subscription ID where initiative will be assigned |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `policy_name` | `string` | `"deploy-datto-rmm-agent"` | Name of the Azure Policy definitions |
| `policy_display_name` | `string` | `"Deploy Datto RMM Agent on Windows VMs"` | Display name of the policies |
| `assignment_name` | `string` | `"assign-datto-rmm-agent"` | Name of the initiative assignment |
| `customer_name` | `string` | `"Default Customer"` | Customer name for logging |
| `enforcement_mode` | `string` | `"Default"` | Policy enforcement mode |
| `location` | `string` | `"West Europe"` | Azure region for managed identity |
| `create_remediation_task` | `bool` | `true` | Whether to create remediation task for existing VMs |
| `guest_config_package_hash` | `string` | `"36580CF2C585556BF43F1CDEA9B5AB620E9EBE45EA5376800A91F1DFE31DCE3F"` | SHA256 hash of your package |
| `tags` | `map(string)` | `{}` | Tags to apply to policy resources |

## Outputs

### Initiative Information
- `policy_initiative_id` - ID of the policy initiative
- `policy_initiative_name` - Name of the policy initiative
- `policy_assignment_id` - ID of the initiative assignment
- `managed_identity_principal_id` - Principal ID of the managed identity

### Compliance Monitoring
- `compliance_check_command` - Azure CLI command to check initiative compliance
- `initiative_compliance_command` - Azure CLI command for compliance summary
- `guest_config_compliance_command` - Azure CLI command for Guest Configuration status
- `policy_portal_url` - Azure Portal URL to view the initiative

### Initiative Structure
- `initiative_structure` - Complete structure showing included policies
- `configuration_summary` - Summary of initiative configuration
- `deployment_status` - Status of all deployed components

## Compliance and Monitoring

### Check Initiative Compliance

Use the Azure CLI to check initiative compliance:

```bash
# Get compliance status for the initiative
az policy state list --policy-assignment 'assign-datto-rmm-agent' --subscription 'your-subscription-id'

# Get compliance summary
az policy state summarize --policy-assignment 'assign-datto-rmm-agent' --subscription 'your-subscription-id'

# Check Guest Configuration assignments
az guestconfig assignment list --subscription 'your-subscription-id' --query "[?name=='InstallDattoRMM']"
```

### Azure Portal

View initiative status in the Azure Portal:
- Navigate to Policy service
- View Assignments to see the Datto RMM initiative
- Check Compliance for VM compliance status across both policies

### PowerShell Monitoring

```powershell
# Check Guest Configuration status on specific VM
Get-AzVMGuestPolicyStatus -ResourceGroupName 'your-rg' -VMName 'your-vm' -InitiativeName 'InstallDattoRMM'

# Check for Datto RMM installation events
Get-EventLog -LogName Application -Source "DattoRMM-DSC" -Newest 10

# Check for Datto RMM services
Get-Service -Name "*Datto*"
```

## Troubleshooting

### Common Issues

1. **Initiative Not Applying**
   - Check initiative assignment scope
   - Verify enforcement mode is set to "Default"
   - Ensure VMs are Windows-based

2. **Guest Configuration Extension Missing**
   - The prerequisite policy should install this automatically
   - Check VM extensions in Azure Portal
   - Verify VM has internet connectivity

3. **Agent Installation Failures**
   - Verify site GUID is correct
   - Check VM internet connectivity for Datto RMM download
   - Review Guest Configuration logs and Event Log entries

4. **Content Hash Errors**
   - Ensure package hash matches your `InstallDattoRMM.zip` file
   - Recalculate hash if package was updated: `Get-FileHash .\InstallDattoRMM.zip`

### Validation Steps

1. **Verify Initiative Deployment**
   ```bash
   az policy set-definition show --name 'deploy-datto-rmm-agent-initiative'
   az policy assignment show --name 'assign-datto-rmm-agent'
   ```

2. **Check VM Extensions**
   ```bash
   az vm extension list --vm-name 'your-vm-name' --resource-group 'your-rg'
   ```

3. **Monitor Remediation**
   ```bash
   az policy remediation show --name 'remediate-datto-rmm-agent'
   ```

## Security Considerations

- Site GUID is marked as sensitive and encrypted in state
- Managed identity uses least-privilege permissions
- Initiative only targets Windows VMs to prevent unnecessary deployments
- Guest Configuration package validated with SHA256 hash
- Cross-tenant deployment supported via SAS token

## Cost Impact

- Azure Policy Initiative: Free
- Individual Policy Definitions: Free
- Managed Identity: Free
- Role Assignments: Free
- VM Extensions: Free
- **Total Additional Cost**: $0/month

The only costs are from the underlying VMs and Datto RMM licensing.

## Package Management

### Updating the Guest Configuration Package

When you update your `InstallDattoRMM.zip` package:

1. **Calculate New Hash**:
   ```powershell
   Get-FileHash .\InstallDattoRMM.zip
   ```

2. **Update Variable**:
   ```hcl
   guest_config_package_hash = "NEW-HASH-VALUE"
   ```

3. **Redeploy Initiative**:
   ```bash
   tofu apply
   ```

### Package Storage

Your existing storage infrastructure is used:
- **Storage Account**: `zenturamspguestconfig`
- **Container**: `guest-configurations`
- **Package**: `InstallDattoRMM.zip`
- **SAS Token**: Long-term access (expires 2035)

## Requirements

- OpenTofu >= 1.0
- AzureRM Provider ~> 3.0
- Appropriate Azure permissions to create policies and role assignments
- Valid Datto RMM site GUID
- Guest Configuration package uploaded to Azure Storage

## Support

This module supports both single-vnet and hub-spoke architectures and integrates seamlessly with the main OpenTofu Azure Landing Zone project.

The Policy Initiative approach provides a single, coordinated deployment that ensures proper dependency ordering and simplified management compared to separate policy deployments.
