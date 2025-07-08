# Data source to get current subscription information
data "azurerm_client_config" "current" {}

# Data source to get subscription details
data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

# Azure Policy Definition for Datto RMM Agent Installation
resource "azurerm_policy_definition" "datto_rmm_agent" {
  name         = var.policy_name
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = var.policy_display_name
  description  = var.policy_description

  metadata = jsonencode({
    category = "Compute"
    version  = "1.0.0"
  })

  parameters = jsonencode({
    siteGuid = {
      type = "String"
      metadata = {
        displayName = "Datto RMM Site GUID"
        description = "The site GUID for Datto RMM agent installation"
      }
    }
    effect = {
      type = "String"
      defaultValue = "DeployIfNotExists"
      allowedValues = [
        "DeployIfNotExists",
        "AuditIfNotExists",
        "Disabled"
      ]
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          field = "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType"
          equals = "Windows"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        type = "Microsoft.Compute/virtualMachines/extensions"
        name = "DattoRMMAgent"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c"  # Virtual Machine Contributor
        ]
        existenceCondition = {
          allOf = [
            {
              field = "Microsoft.Compute/virtualMachines/extensions/type"
              equals = "RunCommandWindows"
            },
            {
              field = "Microsoft.Compute/virtualMachines/extensions/publisher"
              equals = "Microsoft.CPlat.Core"
            },
            {
              field = "name"
              equals = "DattoRMMAgent"
            }
          ]
        }
        deployment = {
          properties = {
            mode = "incremental"
            template = {
              "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                vmName = {
                  type = "string"
                }
                location = {
                  type = "string"
                }
                siteGuid = {
                  type = "string"
                }
              }
              resources = [
                {
                  type = "Microsoft.Compute/virtualMachines/extensions"
                  apiVersion = "2021-11-01"
                  name = "[concat(parameters('vmName'), '/DattoRMMAgent')]"
                  location = "[parameters('location')]"
                  properties = {
                    publisher = "Microsoft.CPlat.Core"
                    type = "RunCommandWindows"
                    typeHandlerVersion = "1.1"
                    autoUpgradeMinorVersion = true
                    settings = {
                      source = {
                        script = "[concat('(New-Object System.Net.WebClient).DownloadFile(\"https://merlot.rmm.datto.com/download-agent/windows/', parameters('siteGuid'), '\", \"$env:TEMP\\AgentInstall.exe\"); Start-Process \"$env:TEMP\\AgentInstall.exe\" -ArgumentList \"/S\" -Wait')]"
                      }
                    }
                    protectedSettings = {}
                  }
                }
              ]
            }
            parameters = {
              vmName = {
                value = "[field('name')]"
              }
              location = {
                value = "[field('location')]"
              }
              siteGuid = {
                value = "[parameters('siteGuid')]"
              }
            }
          }
        }
      }
    }
  })
}

# Policy Assignment at Subscription Level
resource "azurerm_subscription_policy_assignment" "datto_rmm_agent" {
  name                 = var.assignment_name
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.datto_rmm_agent.id
  display_name         = var.assignment_display_name
  description          = var.assignment_description
  location             = var.location
  enforce              = var.enforcement_mode == "Default"

  parameters = jsonencode({
    siteGuid = {
      value = var.site_guid
    }
    effect = {
      value = "DeployIfNotExists"
    }
  })

  identity {
    type = var.identity_type
  }

  metadata = jsonencode({
    assignedBy = "OpenTofu"
    category   = "Compute"
  })
}

# Role Assignment for Policy Assignment Managed Identity
resource "azurerm_role_assignment" "policy_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_subscription_policy_assignment.datto_rmm_agent.identity[0].principal_id

  depends_on = [azurerm_subscription_policy_assignment.datto_rmm_agent]
}

# Additional Role Assignment for Resource Group Contributor (needed for extension deployment)
resource "azurerm_role_assignment" "policy_assignment_rg" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_subscription_policy_assignment.datto_rmm_agent.identity[0].principal_id

  depends_on = [azurerm_subscription_policy_assignment.datto_rmm_agent]
}

# Note: Policy remediation can be triggered manually via Azure Portal or Azure CLI
# The azurerm_policy_remediation resource is not available in the current provider version
# Use this Azure CLI command to trigger remediation manually:
# az policy remediation create --name "remediate-datto-rmm" --policy-assignment "/subscriptions/{subscription-id}/providers/Microsoft.Authorization/policyAssignments/{assignment-name}"

# Wait for role assignment propagation
resource "time_sleep" "wait_for_rbac" {
  count           = var.create_remediation_task ? 1 : 0
  depends_on      = [azurerm_role_assignment.policy_assignment, azurerm_role_assignment.policy_assignment_rg]
  create_duration = "60s"
}
