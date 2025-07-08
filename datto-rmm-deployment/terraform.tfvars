# Datto RMM Policy Deployment Configuration
# Clean deployment for brownfield Azure environments

# Subscription Configuration - Use meaningful names
subscriptions = {
  prod   = "caaf1a53-3a0a-42e4-9688-4aac8f95a2d7"  # Replace with your production subscription ID
  # development  = "52bc998c-51a4-40fa-be04-26774b4c5f0e"  # Replace with your development subscription ID
  # management   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Uncomment and add management subscription if needed
  # connectivity = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Uncomment and add connectivity subscription if needed
  # identity     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Uncomment and add identity subscription if needed
}

# Datto RMM Configuration
datto_rmm_config = {
  site_guid = "d5792943-c2e4-40b3-84b8-dccac61f4d35"  # Replace with your actual Datto RMM site GUID
}

# Azure Region
location = "West Europe"

# Global Tags
global_tags = {
  environment     = "Production"
  project         = "Datto RMM Policy Deployment"
  creation_method = "OpenTofu"
  owner           = "Zentura"
  cost_center     = "IT-Security"
  purpose         = "RMM Agent Deployment"
  deployment_type = "brownfield"
}

# Policy Configuration (Optional - uses smart defaults if not specified)
policy_config = {
  production = {
    enabled                 = true
    policy_name            = "deploy-datto-rmm-agent-production"
    policy_display_name    = "Deploy Datto RMM Agent on Windows VMs (Production)"
    assignment_name        = "assign-datto-rmm-agent-production"
    assignment_display_name = "Assign Datto RMM Agent Policy (Production Environment)"
    create_remediation_task = true
  }
  # management = {
  #   enabled                 = true
  #   policy_name            = "deploy-datto-rmm-agent-management"
  #   policy_display_name    = "Deploy Datto RMM Agent on Windows VMs (Management)"
  #   assignment_name        = "assign-datto-rmm-agent-management"
  #   assignment_display_name = "Assign Datto RMM Agent Policy (Management Environment)"
  #   create_remediation_task = true
  # }
}

# ========================================
# DEPLOYMENT INSTRUCTIONS
# ========================================
#
# 1. PREREQUISITES:
#    - Existing Azure subscriptions with Windows VMs
#    - Appropriate permissions to create policies and role assignments
#    - Valid Datto RMM site GUID
#    - OpenTofu/Terraform installed
#
# 2. CONFIGURATION:
#    - Update subscription IDs above with your actual subscriptions
#    - Update site_guid with your Datto RMM site GUID
#    - Modify subscription names and tags as needed
#    - Add/remove subscriptions as needed (up to 5 supported)
#
# 3. AUTHENTICATION:
#    az login
#    az account list --output table
#    # Test access to each subscription:
#    az account set --subscription "caaf1a53-3a0a-42e4-9688-4aac8f95a2d7"
#    az account set --subscription "52bc998c-51a4-40fa-be04-26774b4c5f0e"
#
# 4. DEPLOY POLICIES:
#    cd datto-rmm-deployment
#    tofu init
#    tofu plan    # Review what policies will be deployed
#    tofu apply   # Deploy the Datto RMM policies
#
# 5. VERIFY DEPLOYMENT:
#    - Check Azure Portal > Policy for new policy definitions and assignments
#    - Verify policy compliance for existing Windows VMs
#    - Monitor policy remediation tasks
#    - Use output URLs for direct Azure Portal access
#
# 6. POLICY SCOPE:
#    - Policies are deployed at subscription level
#    - Automatically applies to ALL Windows VMs in each subscription
#    - Includes existing VMs and future VMs
#
# 7. REMEDIATION:
#    - Policies will automatically remediate non-compliant VMs
#    - Check Azure Portal > Policy > Remediation for status
#    - Use PowerShell commands from outputs for manual operations
#
# ========================================
# WHAT THIS DEPLOYMENT CREATES
# ========================================
#
# Per Subscription:
# - 1x Azure Policy Definition (Custom)
# - 1x Azure Policy Assignment (Subscription scope)
# - 2x Role Assignments (VM Contributor + Contributor for policy identity)
# - 1x Remediation task (automatic)
#
# Example for 2 subscriptions:
# - 2x Policy Definitions
# - 2x Policy Assignments  
# - 4x Role Assignments
# - 2x Remediation tasks
#
# ========================================
# COST IMPACT
# ========================================
#
# Policy Resources: FREE
# - Policy definitions: No cost
# - Policy assignments: No cost
# - Role assignments: No cost
# - Remediation tasks: No cost
#
# Agent Installation: Minimal compute cost during installation
# - Brief CPU/network usage during agent download and install
# - One-time cost per VM (typically < $0.01 per VM)
#
# ========================================
