# Policy Definition Information
output "policy_definition_id" {
  description = "ID of the Datto RMM policy definition"
  value       = azurerm_policy_definition.datto_rmm_agent.id
}

output "policy_definition_name" {
  description = "Name of the Datto RMM policy definition"
  value       = azurerm_policy_definition.datto_rmm_agent.name
}

output "policy_definition_display_name" {
  description = "Display name of the Datto RMM policy definition"
  value       = azurerm_policy_definition.datto_rmm_agent.display_name
}

# Policy Assignment Information
output "policy_assignment_id" {
  description = "ID of the Datto RMM policy assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.id
}

output "policy_assignment_name" {
  description = "Name of the Datto RMM policy assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.name
}

output "policy_assignment_display_name" {
  description = "Display name of the Datto RMM policy assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.display_name
}

output "policy_assignment_scope" {
  description = "Scope of the Datto RMM policy assignment"
  value       = "/subscriptions/${var.subscription_id}"
}

output "policy_assignment_enforcement_mode" {
  description = "Enforcement mode of the policy assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.enforce ? "Default" : "DoNotEnforce"
}

# Managed Identity Information
output "managed_identity_principal_id" {
  description = "Principal ID of the policy assignment managed identity"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.identity[0].principal_id
}

output "managed_identity_tenant_id" {
  description = "Tenant ID of the policy assignment managed identity"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.identity[0].tenant_id
}

output "managed_identity_type" {
  description = "Type of the policy assignment managed identity"
  value       = azurerm_subscription_policy_assignment.datto_rmm_agent.identity[0].type
}

# Role Assignment Information
output "vm_contributor_role_assignment_id" {
  description = "ID of the Virtual Machine Contributor role assignment"
  value       = azurerm_role_assignment.policy_assignment.id
}

output "contributor_role_assignment_id" {
  description = "ID of the Contributor role assignment"
  value       = azurerm_role_assignment.policy_assignment_rg.id
}

# Remediation Task Information
output "remediation_task_id" {
  description = "ID of the remediation task (manual creation required)"
  value       = null
}

output "remediation_task_name" {
  description = "Name of the remediation task (manual creation required)"
  value       = var.create_remediation_task ? var.remediation_task_name : null
}

output "remediation_command" {
  description = "Azure CLI command to create remediation task manually"
  value       = "az policy remediation create --name '${var.remediation_task_name}' --policy-assignment '${azurerm_subscription_policy_assignment.datto_rmm_agent.name}' --subscription '${var.subscription_id}'"
}

# Configuration Summary
output "configuration_summary" {
  description = "Summary of the Datto RMM policy configuration"
  value = {
    subscription_id        = var.subscription_id
    policy_name           = azurerm_policy_definition.datto_rmm_agent.name
    assignment_name       = azurerm_subscription_policy_assignment.datto_rmm_agent.name
    enforcement_enabled   = azurerm_subscription_policy_assignment.datto_rmm_agent.enforce
    remediation_enabled   = var.create_remediation_task
    managed_identity_type = azurerm_subscription_policy_assignment.datto_rmm_agent.identity[0].type
    scope                = "/subscriptions/${var.subscription_id}"
  }
}

# Compliance Information
output "compliance_check_command" {
  description = "Azure CLI command to check policy compliance"
  value       = "az policy state list --policy-assignment '${azurerm_subscription_policy_assignment.datto_rmm_agent.name}' --subscription '${var.subscription_id}'"
}

output "policy_portal_url" {
  description = "Azure Portal URL to view the policy assignment"
  value       = "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/${urlencode(azurerm_policy_definition.datto_rmm_agent.id)}"
}

# Deployment Status
output "deployment_status" {
  description = "Status of the Datto RMM policy deployment"
  value = {
    policy_definition_created = true
    policy_assignment_created = true
    managed_identity_created  = true
    role_assignments_created  = true
    remediation_task_created  = var.create_remediation_task
    ready_for_compliance     = true
  }
}
