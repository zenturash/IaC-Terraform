# Data source to get current subscription information
data "azurerm_client_config" "current" {}

# Data source to get subscription details
data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

# Policy Definition 1: Guest Configuration Extension Prerequisite
resource "azurerm_policy_definition" "guest_config_extension_prerequisite" {
  name         = "${var.policy_name}-prerequisite"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "${var.policy_display_name} - Guest Configuration Extension Prerequisite"
  description  = "Ensures Guest Configuration extension is installed on Windows VMs before applying Datto RMM Guest Configuration"

  metadata = jsonencode({
    category = "Guest Configuration"
    version  = "1.0.0"
  })

  parameters = jsonencode({
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
        name = "AzurePolicyforWindows"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c"  # Virtual Machine Contributor
        ]
        existenceCondition = {
          allOf = [
            {
              field = "Microsoft.Compute/virtualMachines/extensions/type"
              equals = "ConfigurationforWindows"
            },
            {
              field = "Microsoft.Compute/virtualMachines/extensions/publisher"
              equals = "Microsoft.GuestConfiguration"
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
              }
              resources = [
                {
                  type = "Microsoft.Compute/virtualMachines/extensions"
                  apiVersion = "2021-11-01"
                  name = "[concat(parameters('vmName'), '/AzurePolicyforWindows')]"
                  location = "[parameters('location')]"
                  properties = {
                    publisher = "Microsoft.GuestConfiguration"
                    type = "ConfigurationforWindows"
                    typeHandlerVersion = "1.0"
                    autoUpgradeMinorVersion = true
                    enableAutomaticUpgrade = true
                    settings = {}
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
            }
          }
        }
      }
    }
  })
}

# Policy Definition 2: Datto RMM Agent Installation via Guest Configuration
resource "azurerm_policy_definition" "datto_rmm_agent" {
  name         = var.policy_name
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = var.policy_display_name
  description  = var.policy_description

  metadata = jsonencode({
    category = "Guest Configuration"
    version  = "2.0.0"
    requiredProviders = ["Microsoft.GuestConfiguration"]
  })

  parameters = jsonencode({
    siteGuid = {
      type = "String"
      metadata = {
        displayName = "Datto RMM Site GUID"
        description = "The site GUID for Datto RMM agent installation"
      }
    }
    customerName = {
      type = "String"
      defaultValue = "Default Customer"
      metadata = {
        displayName = "Customer Name"
        description = "Customer name for Datto RMM installation logging"
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
        type = "Microsoft.GuestConfiguration/guestConfigurationAssignments"
        name = "InstallDattoRMM"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c",  # Guest Configuration Resource Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c"   # Virtual Machine Contributor
        ]
        existenceCondition = {
          field = "Microsoft.GuestConfiguration/guestConfigurationAssignments/guestConfiguration.name"
          equals = "InstallDattoRMM"
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
                customerName = {
                  type = "string"
                }
                configurationUri = {
                  type = "string"
                }
              }
              resources = [
                {
                  type = "Microsoft.Compute/virtualMachines/providers/guestConfigurationAssignments"
                  apiVersion = "2020-06-25"
                  name = "[concat(parameters('vmName'), '/Microsoft.GuestConfiguration/InstallDattoRMM')]"
                  location = "[parameters('location')]"
                  properties = {
                    guestConfiguration = {
                      name = "InstallDattoRMM"
                      version = "1.0.0"
                      contentUri = "[parameters('configurationUri')]"
                      contentHash = var.guest_config_package_hash
                      configurationParameter = [
                        {
                          name = "InstallDattoRMM;SiteGuid"
                          value = "[parameters('siteGuid')]"
                        },
                        {
                          name = "InstallDattoRMM;CustomerName"
                          value = "[parameters('customerName')]"
                        }
                      ]
                      configurationSetting = {
                        configurationMode = "ApplyAndMonitor"
                        allowModuleOverwrite = true
                        actionAfterReboot = "ContinueConfiguration"
                        refreshFrequencyMins = 30
                        rebootIfNeeded = true
                        configurationModeFrequencyMins = 15
                      }
                    }
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
              customerName = {
                value = "[parameters('customerName')]"
              }
              configurationUri = {
                value = var.guest_config_package_uri
              }
            }
          }
        }
      }
    }
  })
}

# Policy Initiative (Policy Set Definition) - Combines both policies
resource "azurerm_policy_set_definition" "datto_rmm_initiative" {
  name         = "${var.policy_name}-initiative"
  policy_type  = "Custom"
  display_name = "${var.policy_display_name} - Complete Solution"
  description  = "Complete Datto RMM deployment solution: installs Guest Configuration extension and deploys Datto RMM agent on Windows VMs"

  metadata = jsonencode({
    category = "Guest Configuration"
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
    customerName = {
      type = "String"
      defaultValue = "Default Customer"
      metadata = {
        displayName = "Customer Name"
        description = "Customer name for Datto RMM installation logging"
      }
    }
    prerequisiteEffect = {
      type = "String"
      defaultValue = "DeployIfNotExists"
      allowedValues = [
        "DeployIfNotExists",
        "AuditIfNotExists",
        "Disabled"
      ]
      metadata = {
        displayName = "Guest Configuration Extension Effect"
        description = "Effect for Guest Configuration extension installation policy"
      }
    }
    mainEffect = {
      type = "String"
      defaultValue = "DeployIfNotExists"
      allowedValues = [
        "DeployIfNotExists",
        "AuditIfNotExists",
        "Disabled"
      ]
      metadata = {
        displayName = "Datto RMM Installation Effect"
        description = "Effect for Datto RMM Guest Configuration policy"
      }
    }
  })

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.guest_config_extension_prerequisite.id
    reference_id         = "GuestConfigExtensionPrerequisite"
    parameter_values = jsonencode({
      effect = {
        value = "[parameters('prerequisiteEffect')]"
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.datto_rmm_agent.id
    reference_id         = "DattoRMMInstallation"
    parameter_values = jsonencode({
      siteGuid = {
        value = "[parameters('siteGuid')]"
      }
      customerName = {
        value = "[parameters('customerName')]"
      }
      effect = {
        value = "[parameters('mainEffect')]"
      }
    })
  }
}

# Policy Initiative Assignment at Subscription Level
resource "azurerm_subscription_policy_assignment" "datto_rmm_initiative" {
  name                 = var.assignment_name
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_set_definition.datto_rmm_initiative.id
  display_name         = var.assignment_display_name
  description          = var.assignment_description
  location             = var.location
  enforce              = var.enforcement_mode == "Default"

  parameters = jsonencode({
    siteGuid = {
      value = var.site_guid
    }
    customerName = {
      value = var.customer_name
    }
    prerequisiteEffect = {
      value = "DeployIfNotExists"
    }
    mainEffect = {
      value = "DeployIfNotExists"
    }
  })

  identity {
    type = var.identity_type
  }

  metadata = jsonencode({
    assignedBy = "OpenTofu"
    category   = "Guest Configuration"
    deploymentType = "Initiative"
  })
}

# Role Assignment for Guest Configuration Resource Contributor
resource "azurerm_role_assignment" "policy_assignment_guest_config" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  principal_id       = azurerm_subscription_policy_assignment.datto_rmm_initiative.identity[0].principal_id

  depends_on = [azurerm_subscription_policy_assignment.datto_rmm_initiative]
}

# Role Assignment for Virtual Machine Contributor
resource "azurerm_role_assignment" "policy_assignment_vm" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_subscription_policy_assignment.datto_rmm_initiative.identity[0].principal_id

  depends_on = [azurerm_subscription_policy_assignment.datto_rmm_initiative]
}

# Wait for role assignment propagation
resource "time_sleep" "wait_for_rbac" {
  count           = var.create_remediation_task ? 1 : 0
  depends_on      = [azurerm_role_assignment.policy_assignment_guest_config, azurerm_role_assignment.policy_assignment_vm]
  create_duration = "60s"
}
