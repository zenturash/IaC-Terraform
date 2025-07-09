# Variables for Datto RMM Policy Deployment

# Required Variables
variable "subscriptions" {
  description = "Map of subscription names to subscription IDs where Datto RMM policies will be deployed"
  type        = map(string)
  
  validation {
    condition = length(var.subscriptions) > 0 && length(var.subscriptions) <= 5
    error_message = "Must provide between 1 and 5 subscriptions."
  }
  
  validation {
    condition = alltrue([
      for sub_id in values(var.subscriptions) : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", sub_id))
    ])
    error_message = "All subscription IDs must be valid GUIDs."
  }
}

variable "datto_rmm_config" {
  description = "Datto RMM configuration"
  type = object({
    site_guid                     = string
    guest_config_package_filename = string
    guest_config_package_hash     = string
  })
  
  validation {
    condition     = length(var.datto_rmm_config.site_guid) > 0
    error_message = "Datto RMM site GUID must be provided."
  }
  
  validation {
    condition     = can(regex("^InstallDattoRMM-\\d{4}\\.zip$", var.datto_rmm_config.guest_config_package_filename))
    error_message = "Package filename must follow format: InstallDattoRMM-XXXX.zip where XXXX is a 4-digit customer number."
  }
  
  validation {
    condition     = can(regex("^[A-F0-9]{64}$", var.datto_rmm_config.guest_config_package_hash))
    error_message = "Package hash must be a valid 64-character SHA256 hash in uppercase hexadecimal format."
  }
}

variable "customer_config" {
  description = "Customer configuration for Guest Configuration logging"
  type = object({
    customer_name = string
  })
  default = {
    customer_name = "Default Customer"
  }
}

# Optional Variables with Defaults
variable "location" {
  description = "Azure region for policy deployment"
  type        = string
  default     = "West Europe"
}

variable "global_tags" {
  description = "Tags to apply to all policy resources"
  type        = map(string)
  default = {
    project         = "Datto RMM Policy Deployment"
    creation_method = "OpenTofu"
    owner           = "IT Security"
  }
}

variable "policy_config" {
  description = "Policy configuration for each subscription"
  type = map(object({
    enabled                 = optional(bool, true)
    policy_name            = optional(string)
    policy_display_name    = optional(string)
    assignment_name        = optional(string)
    assignment_display_name = optional(string)
    create_remediation_task = optional(bool, true)
  }))
  default = {}
}
