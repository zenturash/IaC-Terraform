# Datto RMM Policy Deployment

This is a clean, standalone deployment for deploying Datto RMM policies to existing Azure environments (brownfield deployments). It uses the existing `azure-policy-datto-rmm` module to deploy policies across multiple subscriptions.

## Overview

This deployment creates Azure Policies that automatically install the Datto RMM agent on Windows VMs across your Azure subscriptions. It's designed for brownfield environments where you already have existing Azure infrastructure and just want to add Datto RMM monitoring.

## Features

- ✅ **Clean Deployment**: Standalone configuration, no infrastructure dependencies
- ✅ **Multi-Subscription Support**: Deploy to up to 5 subscriptions with meaningful names
- ✅ **Flexible Naming**: Use descriptive names like "production", "development", "management"
- ✅ **Automatic Remediation**: Policies automatically install agents on existing and new VMs
- ✅ **Comprehensive Outputs**: Direct Azure Portal links and PowerShell commands
- ✅ **Smart Defaults**: Minimal configuration required, intelligent defaults provided

## Quick Start

### 1. Prerequisites

- Existing Azure subscriptions with Windows VMs
- Appropriate permissions to create policies and role assignments
- Valid Datto RMM site GUID
- OpenTofu or Terraform installed
- Azure CLI installed and authenticated

### 2. Configuration

Edit `terraform.tfvars` and update:

```hcl
# Update with your actual subscription IDs
subscriptions = {
  production  = "your-production-subscription-id"
  development = "your-development-subscription-id"
  # Add more subscriptions as needed
}

# Update with your Datto RMM site GUID
datto_rmm_config = {
  site_guid = "your-datto-rmm-site-guid"
}
```

### 3. Deploy

```bash
# Navigate to deployment folder
cd datto-rmm-deployment

# Initialize OpenTofu
tofu init

# Review deployment plan
tofu plan

# Deploy policies
tofu apply
```

### 4. Verify

After deployment, check:
- Azure Portal > Policy for new policy definitions and assignments
- Policy compliance for existing Windows VMs
- Remediation task status
- Use output URLs for direct Azure Portal access

## Configuration Options

### Subscription Configuration

```hcl
subscriptions = {
  production   = "subscription-id-1"
  development  = "subscription-id-2"
  management   = "subscription-id-3"
  connectivity = "subscription-id-4"
  identity     = "subscription-id-5"
}
```

**Supported subscription names:**
- `production` - Production workloads
- `development` - Development/testing environments
- `management` - Management and monitoring resources
- `connectivity` - Networking and connectivity resources
- `identity` - Identity and access management resources

### Policy Configuration (Optional)

```hcl
policy_config = {
  production = {
    enabled                 = true
    policy_name            = "deploy-datto-rmm-agent-production"
    policy_display_name    = "Deploy Datto RMM Agent on Windows VMs (Production)"
    assignment_name        = "assign-datto-rmm-agent-production"
    assignment_display_name = "Assign Datto RMM Agent Policy (Production Environment)"
    create_remediation_task = true
  }
}
```

If not specified, smart defaults are used based on subscription names.

## What Gets Created

### Per Subscription:
- 1x Azure Policy Definition (Custom)
- 1x Azure Policy Assignment (Subscription scope)
- 2x Role Assignments (VM Contributor + Contributor for policy identity)
- 1x Remediation task (automatic)

### Example for 2 subscriptions:
- 2x Policy Definitions
- 2x Policy Assignments  
- 4x Role Assignments
- 2x Remediation tasks

## Outputs

The deployment provides comprehensive outputs:

### Policy Information
- Policy definition IDs and names
- Policy assignment IDs and names
- Subscription mappings

### Azure Portal Links
- Direct links to policy definitions
- Direct links to policy assignments
- Direct links to compliance dashboards

### PowerShell Commands
- Commands to check policy compliance
- Commands to trigger manual remediation
- Commands to check remediation status

## PowerShell Script Execution

The policy automatically executes this script on Windows VMs:

```powershell
(New-Object System.Net.WebClient).DownloadFile("https://merlot.rmm.datto.com/download-agent/windows/[SITE-GUID]", "$env:TEMP/AgentInstall.exe");
Start-Process "$env:TEMP/AgentInstall.exe" -Wait
```

## Cost Impact

### Policy Resources: **FREE**
- Policy definitions: No cost
- Policy assignments: No cost
- Role assignments: No cost
- Remediation tasks: No cost

### Agent Installation: **Minimal**
- Brief CPU/network usage during agent download and install
- One-time cost per VM (typically < $0.01 per VM)

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Ensure you have Policy Contributor role on target subscriptions
   - Ensure you have User Access Administrator role for role assignments

2. **Policy Not Applying**
   - Check policy compliance in Azure Portal
   - Verify VMs are Windows-based
   - Check remediation task status

3. **Agent Installation Fails**
   - Verify Datto RMM site GUID is correct
   - Check VM internet connectivity
   - Review VM extension logs in Azure Portal

### Manual Operations

Use the PowerShell commands from outputs for manual operations:

```powershell
# Check compliance
Get-AzPolicyState -SubscriptionId 'subscription-id' -PolicyAssignmentName 'assignment-name'

# Trigger remediation
Start-AzPolicyRemediation -SubscriptionId 'subscription-id' -PolicyAssignmentId 'assignment-id' -Name 'remediate-datto-rmm'

# Check remediation status
Get-AzPolicyRemediation -SubscriptionId 'subscription-id' -PolicyAssignmentId 'assignment-id'
```

## File Structure

```
datto-rmm-deployment/
├── main.tf              # Main deployment configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── terraform.tfvars     # Configuration values
└── README.md            # This documentation
```

## Support

For issues with:
- **Azure Policy**: Check Azure Portal > Policy > Compliance
- **Datto RMM**: Contact Datto support with site GUID
- **OpenTofu/Terraform**: Check configuration and permissions

## Security Considerations

- Policies are deployed at subscription level (broad scope)
- Managed identities are used for policy execution
- Role assignments follow principle of least privilege
- Agent installation uses HTTPS download
- No sensitive data is stored in policy definitions
