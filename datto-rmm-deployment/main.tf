# Datto RMM Policy Deployment for Brownfield Azure Environments
# Simple deployment using the existing azure-policy-datto-rmm module

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Microsoft Azure Provider (Default)
provider "azurerm" {
  features {}
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Deploy Datto RMM Policy to each subscription
module "datto_rmm_policies" {
  for_each = var.subscriptions
  source   = "../modules/azure-policy-datto-rmm"

  # Required variables
  site_guid       = var.datto_rmm_config.site_guid
  subscription_id = each.value
  location        = var.location
  
  # Guest Configuration package details
  guest_config_package_filename = var.datto_rmm_config.guest_config_package_filename
  guest_config_package_hash     = var.datto_rmm_config.guest_config_package_hash

  # Customer configuration
  customer_name = var.customer_config.customer_name

  # Policy configuration - use custom names if provided, otherwise use defaults
  policy_name                = try(var.policy_config[each.key].policy_name, "deploy-datto-rmm-agent-${each.key}")
  policy_display_name        = try(var.policy_config[each.key].policy_display_name, "Deploy Datto RMM Agent on Windows VMs (${title(each.key)})")
  assignment_name            = try(var.policy_config[each.key].assignment_name, "assign-datto-rmm-agent-${each.key}")
  assignment_display_name    = try(var.policy_config[each.key].assignment_display_name, "Assign Datto RMM Agent Policy (${title(each.key)})")
  create_remediation_task    = try(var.policy_config[each.key].create_remediation_task, true)

  # Tags
  tags = merge(var.global_tags, {
    creation_date     = formatdate("YYYY-MM-DD", timestamp())
    subscription_name = each.key
    subscription_id   = each.value
    deployment_type   = "brownfield"
    component         = "datto-rmm"
  })
}
