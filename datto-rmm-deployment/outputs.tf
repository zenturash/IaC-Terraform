# Outputs for Datto RMM Policy Initiative Deployment

# Policy Initiative Information
output "policy_initiatives" {
  description = "Information about the deployed policy initiatives"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      initiative_id           = v.policy_initiative_id
      initiative_name         = v.policy_initiative_name
      initiative_display_name = v.policy_initiative_display_name
    }
  }
}

# Policy Initiative Assignments
output "policy_assignments" {
  description = "Information about the deployed policy initiative assignments"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      assignment_id           = v.policy_assignment_id
      assignment_name         = v.policy_assignment_name
      assignment_display_name = v.policy_assignment_display_name
      subscription_id         = var.subscriptions[k]
    }
  }
}

# Individual Policy Definitions within Initiatives
output "policy_definitions" {
  description = "Information about individual policy definitions within initiatives"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      prerequisite_policy_id = v.prerequisite_policy_definition_id
      main_policy_id         = v.main_policy_definition_id
      main_policy_name       = v.main_policy_definition_name
      main_policy_display_name = v.main_policy_definition_display_name
    }
  }
}

# Initiative Structure
output "initiative_structure" {
  description = "Structure of deployed policy initiatives"
  value = {
    for k, v in module.datto_rmm_policies : k => v.initiative_structure
  }
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of the Datto RMM policy initiative deployment"
  value = {
    total_subscriptions = length(var.subscriptions)
    deployment_method   = "Policy Initiative"
    subscriptions = {
      for k, v in var.subscriptions : k => {
        subscription_id = v
        initiative_deployed = contains(keys(module.datto_rmm_policies), k)
      }
    }
    site_guid = var.datto_rmm_config.site_guid
    customer_name = var.customer_config.customer_name
    location  = var.location
  }
}

# Remediation Information
output "remediation_status" {
  description = "Remediation task status for each subscription"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      remediation_enabled = v.configuration_summary.remediation_enabled
      subscription_id     = var.subscriptions[k]
      deployment_method   = v.configuration_summary.deployment_method
    }
  }
}

# Connection Information
output "azure_portal_links" {
  description = "Direct links to Azure Portal for policy initiative management"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      initiative_definition_url = v.policy_portal_url
      initiative_assignment_url = "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyAssignmentDetailsBlade/assignmentId/${urlencode(v.policy_assignment_id)}"
      compliance_url           = "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyComplianceBlade/assignmentId/${urlencode(v.policy_assignment_id)}"
    }
  }
}

# Azure CLI Commands for Manual Operations
output "azure_cli_commands" {
  description = "Azure CLI commands for manual policy initiative operations"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      check_compliance        = v.compliance_check_command
      check_initiative_summary = v.initiative_compliance_command
      check_guest_config      = v.guest_config_compliance_command
      trigger_remediation     = v.remediation_command
      check_remediation       = "az policy remediation list --subscription '${var.subscriptions[k]}' --policy-assignment '${v.policy_assignment_name}'"
    }
  }
}

# Configuration Summary
output "configuration_summary" {
  description = "Complete configuration summary for each subscription"
  value = {
    for k, v in module.datto_rmm_policies : k => v.configuration_summary
  }
}

# Deployment Status
output "deployment_status" {
  description = "Deployment status for each subscription"
  value = {
    for k, v in module.datto_rmm_policies : k => v.deployment_status
  }
}

# Guest Configuration Information
output "guest_configuration_info" {
  description = "Guest Configuration package information"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      package_name    = v.guest_config_name
      package_version = v.guest_config_version
      package_hash    = v.guest_config_package_hash
      customer_name   = v.configuration_summary.customer_name
    }
  }
}

# Managed Identity Information
output "managed_identities" {
  description = "Managed identity information for policy initiatives"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      principal_id = v.managed_identity_principal_id
      tenant_id    = v.managed_identity_tenant_id
      type         = v.managed_identity_type
    }
  }
}
