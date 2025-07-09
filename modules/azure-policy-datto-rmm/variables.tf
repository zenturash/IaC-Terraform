# Required Variables
variable "site_guid" {
  description = "Datto RMM site GUID for agent installation"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.site_guid) > 0
    error_message = "Site GUID must not be empty."
  }
  
  validation {
    condition     = can(regex("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$", var.site_guid))
    error_message = "Site GUID must be a valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID where the policy will be assigned"
  type        = string
  
  validation {
    condition     = can(regex("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid UUID format."
  }
}

# Optional Variables with Defaults
variable "policy_name" {
  description = "Name of the Azure Policy definition"
  type        = string
  default     = "deploy-datto-rmm-agent"
}

variable "policy_display_name" {
  description = "Display name of the Azure Policy definition"
  type        = string
  default     = "Deploy Datto RMM Agent on Windows VMs"
}

variable "policy_description" {
  description = "Description of the Azure Policy definition"
  type        = string
  default     = "Automatically deploys Datto RMM agent on Windows virtual machines using Azure Guest Configuration"
}

variable "guest_config_package_uri" {
  description = "URI to the Guest Configuration package with SAS token"
  type        = string
  default     = "https://zenturamspguestconfig.blob.core.windows.net/guest-configurations/InstallDattoRMM.zip?sp=rl&st=2025-07-08T14:33:32Z&se=2035-08-09T22:33:32Z&spr=https&sv=2024-11-04&sr=c&sig=rvcknUpe7QAkUOGYTHh6aKMrYNK0ujOMQacz19Osc24%3D"
  sensitive   = true
}

variable "guest_config_package_hash" {
  description = "SHA256 hash of the Guest Configuration package for content validation"
  type        = string
  default     = "36580CF2C585556BF43F1CDEA9B5AB620E9EBE45EA5376800A91F1DFE31DCE3F"
  
  validation {
    condition     = can(regex("^[A-F0-9]{64}$", var.guest_config_package_hash))
    error_message = "Package hash must be a valid 64-character SHA256 hash in uppercase hexadecimal format."
  }
}

variable "customer_name" {
  description = "Customer name for Datto RMM installation logging"
  type        = string
  default     = "Default Customer"
}

variable "assignment_name" {
  description = "Name of the policy assignment"
  type        = string
  default     = "assign-datto-rmm-agent"
}

variable "assignment_display_name" {
  description = "Display name of the policy assignment"
  type        = string
  default     = "Assign Datto RMM Agent Policy"
}

variable "assignment_description" {
  description = "Description of the policy assignment"
  type        = string
  default     = "Assignment to deploy Datto RMM agent on all Windows VMs in subscription"
}

variable "enforcement_mode" {
  description = "Policy enforcement mode"
  type        = string
  default     = "Default"
  
  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.enforcement_mode)
    error_message = "Enforcement mode must be either 'Default' or 'DoNotEnforce'."
  }
}

variable "identity_type" {
  description = "Type of managed identity for policy assignment"
  type        = string
  default     = "SystemAssigned"
  
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "Identity type must be either 'SystemAssigned' or 'UserAssigned'."
  }
}

variable "location" {
  description = "Azure region for managed identity location"
  type        = string
  default     = "West Europe"
}

variable "create_remediation_task" {
  description = "Whether to create a remediation task for existing non-compliant VMs"
  type        = bool
  default     = true
}

variable "remediation_task_name" {
  description = "Name of the remediation task"
  type        = string
  default     = "remediate-datto-rmm-agent"
}

variable "tags" {
  description = "Tags to apply to policy resources"
  type        = map(string)
  default     = {}
}
