# Azure Policy - Datto RMM Agent Module

This OpenTofu module creates and deploys a custom Azure Policy that automatically installs the Datto RMM agent on Windows virtual machines.

## Features

- **Custom Azure Policy Definition**: Creates a policy that targets Windows VMs
- **Automatic Installation**: Uses `DeployIfNotExists` effect to install Datto RMM agent
- **Subscription-Level Enforcement**: Applies policy at subscription scope
- **Managed Identity**: Creates system-assigned identity with required permissions
- **Automatic Remediation**: Remediates existing non-compliant VMs immediately
- **Parameterized Site GUID**: Configurable Datto RMM site identifier

## Architecture

The module deploys:

1. **Azure Policy Definition** - Custom policy targeting Windows VMs
2. **Policy Assignment** - Subscription-level assignment with enforcement
3. **Managed Identity** - System-assigned identity for policy execution
4. **Role Assignments** - Required permissions (Virtual Machine Contributor, Contributor)
5. **Remediation Task** - Immediate remediation for existing VMs

## PowerShell Script

The policy executes this PowerShell script on Windows VMs:

```powershell
(New-Object System.Net.WebClient).DownloadFile("https://merlot.rmm.datto.com/download-agent/windows/[SITE-GUID]", "$env:TEMP/AgentInstall.exe");
Start-Process "$env:TEMP/AgentInstall.exe" -Wait
```

Where `[SITE-GUID]` is replaced with your Datto RMM site GUID parameter.

## Usage

### Basic Usage

```hcl
module "datto_rmm_policy" {
  source = "./modules/azure-policy-datto-rmm"

  # Required variables
  site_guid       = "d5792943-c2e4-40b3-84b8-dccac61f4d35"  # Your Datto RMM site GUID
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  location        = "West Europe"

  # Optional customization
  policy_name             = "deploy-datto-rmm-agent"
  assignment_name         = "assign-datto-rmm-agent"
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
  datto_policy = true  # Enable Datto RMM policy
}

datto_rmm_config = {
  enabled   = true
  site_guid = "d5792943-c2e4-40b3-84b8-dccac61f4d35"  # Your actual site GUID
}
```

## Architecture Support

### Single VNet Mode
- Deploys one policy to the default subscription
- Targets all Windows VMs in the single VNet

### Hub-Spoke Mode
- Deploys policy to each spoke subscription
- Excludes hub subscription (no VMs should be there)
- Uses spoke subscription IDs from `subscriptions.spoke` map

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `site_guid` | `string` | Datto RMM site GUID for agent installation |
| `subscription_id` | `string` | Azure subscription ID where policy will be assigned |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `policy_name` | `string` | `"deploy-datto-rmm-agent"` | Name of the Azure Policy definition |
| `policy_display_name` | `string` | `"Deploy Datto RMM Agent on Windows VMs"` | Display name of the policy |
| `assignment_name` | `string` | `"assign-datto-rmm-agent"` | Name of the policy assignment |
| `enforcement_mode` | `string` | `"Default"` | Policy enforcement mode |
| `location` | `string` | `"West Europe"` | Azure region for managed identity |
| `create_remediation_task` | `bool` | `true` | Whether to create remediation task for existing VMs |
| `tags` | `map(string)` | `{}` | Tags to apply to policy resources |

## Outputs

### Policy Information
- `policy_definition_id` - ID of the policy definition
- `policy_assignment_id` - ID of the policy assignment
- `managed_identity_principal_id` - Principal ID of the managed identity

### Compliance Monitoring
- `compliance_check_command` - Azure CLI command to check compliance
- `policy_portal_url` - Azure Portal URL to view the policy
- `configuration_summary` - Summary of policy configuration

### Deployment Status
- `deployment_status` - Status of all deployed components
- `remediation_task_id` - ID of the remediation task (if created)

## Compliance and Monitoring

### Check Policy Compliance

Use the Azure CLI to check policy compliance:

```bash
# Get compliance status
az policy state list --policy-assignment 'assign-datto-rmm-agent' --subscription 'your-subscription-id'

# Get compliance summary
az policy state summarize --policy-assignment 'assign-datto-rmm-agent' --subscription 'your-subscription-id'
```

### Azure Portal

View policy status in the Azure Portal:
- Navigate to Policy service
- View Assignments to see the Datto RMM policy
- Check Compliance for VM compliance status

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Ensure the managed identity has proper role assignments
   - Wait 60 seconds after deployment for RBAC propagation

2. **Policy Not Applying**
   - Check policy assignment scope
   - Verify enforcement mode is set to "Default"
   - Ensure VMs are Windows-based

3. **Agent Installation Failures**
   - Verify site GUID is correct
   - Check VM internet connectivity
   - Review VM extension logs in Azure Portal

### Validation Steps

1. **Verify Policy Deployment**
   ```bash
   az policy definition show --name 'deploy-datto-rmm-agent'
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
- Policy only targets Windows VMs to prevent unnecessary deployments
- PowerShell execution is restricted to the specific installation script

## Cost Impact

- Azure Policy: Free
- Managed Identity: Free
- Role Assignments: Free
- VM Extensions: Free
- **Total Additional Cost**: $0/month

The only costs are from the underlying VMs and Datto RMM licensing.

## Requirements

- OpenTofu >= 1.0
- AzureRM Provider ~> 3.0
- Appropriate Azure permissions to create policies and role assignments
- Valid Datto RMM site GUID

## Support

This module supports both single-vnet and hub-spoke architectures and integrates seamlessly with the main OpenTofu Azure Landing Zone project.
