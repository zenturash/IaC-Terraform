# Outputs for Datto RMM Policy Deployment

# Policy Information
output "policy_definitions" {
  description = "Information about the deployed policy definitions"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      policy_id           = v.policy_definition_id
      policy_name         = v.policy_definition_name
      policy_display_name = v.policy_definition_display_name
    }
  }
}

output "policy_assignments" {
  description = "Information about the deployed policy assignments"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      assignment_id           = v.policy_assignment_id
      assignment_name         = v.policy_assignment_name
      assignment_display_name = v.policy_assignment_display_name
      subscription_id         = var.subscriptions[k]
    }
  }
}

output "deployment_summary" {
  description = "Summary of the Datto RMM policy deployment"
  value = {
    total_subscriptions = length(var.subscriptions)
    subscriptions = {
      for k, v in var.subscriptions : k => {
        subscription_id = v
        policy_deployed = contains(keys(module.datto_rmm_policies), k)
      }
    }
    site_guid = var.datto_rmm_config.site_guid
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
    }
  }
}

# Connection Information
output "azure_portal_links" {
  description = "Direct links to Azure Portal for policy management"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      policy_definition_url = v.policy_portal_url
      policy_assignment_url = "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyAssignmentDetailsBlade/assignmentId/${urlencode(v.policy_assignment_id)}"
      compliance_url        = "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyComplianceBlade/assignmentId/${urlencode(v.policy_assignment_id)}"
    }
  }
}

# Azure CLI Commands for Manual Operations
output "azure_cli_commands" {
  description = "Azure CLI commands for manual policy operations"
  value = {
    for k, v in module.datto_rmm_policies : k => {
      check_compliance    = v.compliance_check_command
      trigger_remediation = v.remediation_command
      check_remediation   = "az policy remediation list --subscription '${var.subscriptions[k]}' --policy-assignment '${v.policy_assignment_name}'"
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
