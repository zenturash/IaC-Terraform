# Policy Initiative Information
output "policy_initiative_id" {
  description = "ID of the Datto RMM policy initiative"
  value       = azurerm_policy_set_definition.datto_rmm_initiative.id
}

output "policy_initiative_name" {
  description = "Name of the Datto RMM policy initiative"
  value       = azurerm_policy_set_definition.datto_rmm_initiative.name
}

output "policy_initiative_display_name" {
  description = "Display name of the Datto RMM policy initiative"
  value       = azurerm_policy_set_definition.datto_rmm_initiative.display_name
}

# Individual Policy Definition Information
output "prerequisite_policy_definition_id" {
  description = "ID of the Guest Configuration extension prerequisite policy definition"
  value       = azurerm_policy_definition.guest_config_extension_prerequisite.id
}

output "main_policy_definition_id" {
  description = "ID of the Datto RMM policy definition"
  value       = azurerm_policy_definition.datto_rmm_agent.id
}

output "main_policy_definition_name" {
  description = "Name of the Datto RMM policy definition"
  value       = azurerm_policy_definition.datto_rmm_agent.name
}

output "main_policy_definition_display_name" {
  description = "Display name of the Datto RMM policy definition"
  value       = azurerm_policy_definition.datto_rmm_agent.display_name
}

# Policy Initiative Assignment Information
output "policy_assignment_id" {
  description = "ID of the Datto RMM policy initiative assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.id
}

output "policy_assignment_name" {
  description = "Name of the Datto RMM policy initiative assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.name
}

output "policy_assignment_display_name" {
  description = "Display name of the Datto RMM policy initiative assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.display_name
}

output "policy_assignment_scope" {
  description = "Scope of the Datto RMM policy initiative assignment"
  value       = "/subscriptions/${var.subscription_id}"
}

output "policy_assignment_enforcement_mode" {
  description = "Enforcement mode of the policy initiative assignment"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.enforce ? "Default" : "DoNotEnforce"
}

# Managed Identity Information
output "managed_identity_principal_id" {
  description = "Principal ID of the policy initiative assignment managed identity"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.identity[0].principal_id
}

output "managed_identity_tenant_id" {
  description = "Tenant ID of the policy initiative assignment managed identity"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.identity[0].tenant_id
}

output "managed_identity_type" {
  description = "Type of the policy initiative assignment managed identity"
  value       = azurerm_subscription_policy_assignment.datto_rmm_initiative.identity[0].type
}

# Role Assignment Information
output "guest_config_role_assignment_id" {
  description = "ID of the Guest Configuration Resource Contributor role assignment"
  value       = azurerm_role_assignment.policy_assignment_guest_config.id
}

output "vm_contributor_role_assignment_id" {
  description = "ID of the Virtual Machine Contributor role assignment"
  value       = azurerm_role_assignment.policy_assignment_vm.id
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
  value       = "az policy remediation create --name '${var.remediation_task_name}' --policy-assignment '${azurerm_subscription_policy_assignment.datto_rmm_initiative.name}' --subscription '${var.subscription_id}'"
}

# Guest Configuration Information
output "guest_config_package_uri" {
  description = "URI of the Guest Configuration package"
  value       = "${var.guest_config_base_url}/${var.guest_config_package_filename}${var.guest_config_sas_token}"
  sensitive   = true
}

output "guest_config_package_hash" {
  description = "SHA256 hash of the Guest Configuration package"
  value       = var.guest_config_package_hash
}

output "guest_config_name" {
  description = "Name of the Guest Configuration"
  value       = "InstallDattoRMM"
}

output "guest_config_version" {
  description = "Version of the Guest Configuration"
  value       = "1.0.0"
}

# Configuration Summary
output "configuration_summary" {
  description = "Summary of the Datto RMM Guest Configuration initiative"
  value = {
    subscription_id        = var.subscription_id
    initiative_name        = azurerm_policy_set_definition.datto_rmm_initiative.name
    assignment_name        = azurerm_subscription_policy_assignment.datto_rmm_initiative.name
    enforcement_enabled    = azurerm_subscription_policy_assignment.datto_rmm_initiative.enforce
    remediation_enabled    = var.create_remediation_task
    managed_identity_type  = azurerm_subscription_policy_assignment.datto_rmm_initiative.identity[0].type
    scope                 = "/subscriptions/${var.subscription_id}"
    deployment_method     = "Policy Initiative"
    guest_config_name     = "InstallDattoRMM"
    customer_name         = var.customer_name
    policies_included     = [
      "Guest Configuration Extension Prerequisite",
      "Datto RMM Guest Configuration Installation"
    ]
  }
}

# Compliance Information
output "compliance_check_command" {
  description = "Azure CLI command to check policy initiative compliance"
  value       = "az policy state list --policy-assignment '${azurerm_subscription_policy_assignment.datto_rmm_initiative.name}' --subscription '${var.subscription_id}'"
}

output "initiative_compliance_command" {
  description = "Azure CLI command to check initiative compliance summary"
  value       = "az policy state summarize --policy-assignment '${azurerm_subscription_policy_assignment.datto_rmm_initiative.name}' --subscription '${var.subscription_id}'"
}

output "guest_config_compliance_command" {
  description = "Azure CLI command to check Guest Configuration compliance"
  value       = "az guestconfig assignment list --subscription '${var.subscription_id}' --query \"[?name=='InstallDattoRMM']\""
}

output "guest_config_status_command" {
  description = "PowerShell command to check Guest Configuration status on VM"
  value       = "Get-AzVMGuestPolicyStatus -ResourceGroupName '<rg-name>' -VMName '<vm-name>' -InitiativeName 'InstallDattoRMM'"
}

output "policy_portal_url" {
  description = "Azure Portal URL to view the policy initiative assignment"
  value       = "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/${urlencode(azurerm_policy_set_definition.datto_rmm_initiative.id)}"
}

# Deployment Status
output "deployment_status" {
  description = "Status of the Datto RMM policy initiative deployment"
  value = {
    initiative_created           = true
    prerequisite_policy_created  = true
    main_policy_created         = true
    initiative_assignment_created = true
    managed_identity_created    = true
    role_assignments_created    = true
    remediation_task_created    = var.create_remediation_task
    ready_for_compliance       = true
    deployment_type            = "Policy Initiative"
  }
}

# Initiative Structure Information
output "initiative_structure" {
  description = "Structure of the policy initiative showing included policies"
  value = {
    initiative_name = azurerm_policy_set_definition.datto_rmm_initiative.name
    policies = [
      {
        reference_id = "GuestConfigExtensionPrerequisite"
        policy_name = azurerm_policy_definition.guest_config_extension_prerequisite.name
        display_name = azurerm_policy_definition.guest_config_extension_prerequisite.display_name
        purpose = "Installs Guest Configuration extension on Windows VMs"
      },
      {
        reference_id = "DattoRMMInstallation"
        policy_name = azurerm_policy_definition.datto_rmm_agent.name
        display_name = azurerm_policy_definition.datto_rmm_agent.display_name
        purpose = "Deploys Datto RMM agent via Guest Configuration"
      }
    ]
  }
}
