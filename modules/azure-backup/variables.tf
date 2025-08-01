# ============================================================================
# REQUIRED VARIABLES (Minimal Requirements)
# ============================================================================

variable "resource_group_name" {
  description = "Name of the resource group for backup resources"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

# ============================================================================
# CORE CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "location" {
  description = "Azure region where backup resources will be created"
  type        = string
  default     = "West Europe"
  
  validation {
    condition     = length(var.location) > 0
    error_message = "Location cannot be empty."
  }
}

variable "backup_vault_name" {
  description = "Name of the backup vault. If null, will auto-generate with timestamp"
  type        = string
  default     = null
  
  validation {
    condition     = var.backup_vault_name == null || (length(var.backup_vault_name) > 0 && length(var.backup_vault_name) <= 50)
    error_message = "Backup vault name must be between 1 and 50 characters when specified."
  }
}

variable "recovery_vault_name" {
  description = "Name of the recovery services vault. If null, will auto-generate with timestamp"
  type        = string
  default     = null
  
  validation {
    condition     = var.recovery_vault_name == null || (length(var.recovery_vault_name) > 0 && length(var.recovery_vault_name) <= 50)
    error_message = "Recovery vault name must be between 1 and 50 characters when specified."
  }
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

# ============================================================================
# BACKUP VAULT CONFIGURATION (ARM Template Defaults)
# ============================================================================

variable "backup_vault_storage_redundancy" {
  description = "Storage redundancy type for backup vault"
  type        = string
  default     = "GeoRedundant"
  
  validation {
    condition     = contains(["LocallyRedundant", "GeoRedundant", "ZoneRedundant"], var.backup_vault_storage_redundancy)
    error_message = "Storage redundancy must be LocallyRedundant, GeoRedundant, or ZoneRedundant."
  }
}

variable "backup_vault_soft_delete_state" {
  description = "State of soft delete for backup vault"
  type        = string
  default     = "On"
  
  validation {
    condition     = contains(["On", "Off"], var.backup_vault_soft_delete_state)
    error_message = "Soft delete state must be On or Off."
  }
}

variable "backup_vault_soft_delete_retention_days" {
  description = "Soft delete retention period in days for backup vault"
  type        = number
  default     = 14
  
  validation {
    condition     = var.backup_vault_soft_delete_retention_days >= 14 && var.backup_vault_soft_delete_retention_days <= 180
    error_message = "Soft delete retention days must be between 14 and 180."
  }
}

variable "backup_vault_replicated_regions" {
  description = "List of replicated regions for backup vault"
  type        = list(string)
  default     = ["northeurope"]
  
  validation {
    condition     = length(var.backup_vault_replicated_regions) > 0
    error_message = "At least one replicated region must be specified."
  }
}

# ============================================================================
# RECOVERY SERVICES VAULT CONFIGURATION (ARM Template Defaults)
# ============================================================================

variable "recovery_vault_sku_name" {
  description = "SKU name for Recovery Services Vault"
  type        = string
  default     = "RS0"
  
  validation {
    condition     = contains(["RS0"], var.recovery_vault_sku_name)
    error_message = "Recovery vault SKU name must be RS0."
  }
}

variable "recovery_vault_sku_tier" {
  description = "SKU tier for Recovery Services Vault"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard"], var.recovery_vault_sku_tier)
    error_message = "Recovery vault SKU tier must be Standard."
  }
}

variable "recovery_vault_soft_delete_enabled" {
  description = "Enable soft delete for Recovery Services Vault"
  type        = bool
  default     = true
}

variable "recovery_vault_soft_delete_retention_days" {
  description = "Soft delete retention period in days for Recovery Services Vault"
  type        = number
  default     = 14
  
  validation {
    condition     = var.recovery_vault_soft_delete_retention_days >= 14 && var.recovery_vault_soft_delete_retention_days <= 180
    error_message = "Soft delete retention days must be between 14 and 180."
  }
}

variable "recovery_vault_enhanced_security_state" {
  description = "Enhanced security state for Recovery Services Vault"
  type        = string
  default     = "Enabled"
  
  validation {
    condition     = contains(["Enabled", "Disabled"], var.recovery_vault_enhanced_security_state)
    error_message = "Enhanced security state must be Enabled or Disabled."
  }
}

variable "recovery_vault_storage_redundancy" {
  description = "Storage redundancy for Recovery Services Vault"
  type        = string
  default     = "GeoRedundant"
  
  validation {
    condition     = contains(["LocallyRedundant", "GeoRedundant", "ZoneRedundant"], var.recovery_vault_storage_redundancy)
    error_message = "Storage redundancy must be LocallyRedundant, GeoRedundant, or ZoneRedundant."
  }
}

variable "recovery_vault_cross_region_restore" {
  description = "Enable cross region restore for Recovery Services Vault"
  type        = bool
  default     = false
}

variable "recovery_vault_public_network_access" {
  description = "Public network access for Recovery Services Vault"
  type        = string
  default     = "Enabled"
  
  validation {
    condition     = contains(["Enabled", "Disabled"], var.recovery_vault_public_network_access)
    error_message = "Public network access must be Enabled or Disabled."
  }
}

variable "recovery_vault_cross_subscription_restore" {
  description = "Enable cross subscription restore for Recovery Services Vault"
  type        = bool
  default     = true
}

# ============================================================================
# BACKUP POLICIES CONFIGURATION (Security-First - Opt-in)
# ============================================================================

variable "create_backup_policies" {
  description = "Map of backup policy types to create (security-first: all disabled by default)"
  type = object({
    vm_daily        = optional(bool, false)
    vm_enhanced     = optional(bool, false)
    files_daily     = optional(bool, false)
    blob_daily      = optional(bool, false)
    sql_hourly_log  = optional(bool, false)
  })
  default = {
    vm_daily        = false
    vm_enhanced     = false
    files_daily     = false
    blob_daily      = false
    sql_hourly_log  = false
  }
}

# ============================================================================
# VM BACKUP POLICY CONFIGURATION
# ============================================================================

variable "vm_backup_time" {
  description = "Time for VM backups in UTC (HH:MM format)"
  type        = string
  default     = "01:00"
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.vm_backup_time))
    error_message = "VM backup time must be in HH:MM format (24-hour)."
  }
}

variable "vm_backup_retention_days" {
  description = "Retention period in days for VM backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.vm_backup_retention_days >= 7 && var.vm_backup_retention_days <= 9999
    error_message = "VM backup retention days must be between 7 and 9999."
  }
}

variable "vm_backup_timezone" {
  description = "Timezone for VM backup schedules"
  type        = string
  default     = "Romance Standard Time"
}

variable "vm_instant_rp_retention_days" {
  description = "Instant recovery point retention in days"
  type        = number
  default     = 2
  
  validation {
    condition     = var.vm_instant_rp_retention_days >= 1 && var.vm_instant_rp_retention_days <= 5
    error_message = "Instant RP retention days must be between 1 and 5."
  }
}

# ============================================================================
# ENHANCED VM BACKUP POLICY CONFIGURATION
# ============================================================================

variable "vm_enhanced_backup_interval_hours" {
  description = "Backup interval in hours for enhanced VM policy"
  type        = number
  default     = 4
  
  validation {
    condition     = contains([4, 6, 8, 12], var.vm_enhanced_backup_interval_hours)
    error_message = "Enhanced backup interval must be 4, 6, 8, or 12 hours."
  }
}

variable "vm_enhanced_backup_window_start" {
  description = "Backup window start time for enhanced VM policy (HH:MM format)"
  type        = string
  default     = "08:00"
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.vm_enhanced_backup_window_start))
    error_message = "Enhanced backup window start must be in HH:MM format (24-hour)."
  }
}

variable "vm_enhanced_backup_window_duration" {
  description = "Backup window duration in hours for enhanced VM policy"
  type        = number
  default     = 12
  
  validation {
    condition     = var.vm_enhanced_backup_window_duration >= 4 && var.vm_enhanced_backup_window_duration <= 20
    error_message = "Enhanced backup window duration must be between 4 and 20 hours."
  }
}

# ============================================================================
# FILES BACKUP POLICY CONFIGURATION
# ============================================================================

variable "files_backup_time" {
  description = "Time for Azure Files backups in UTC (HH:MM format)"
  type        = string
  default     = "01:00"
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.files_backup_time))
    error_message = "Files backup time must be in HH:MM format (24-hour)."
  }
}

variable "files_backup_retention_days" {
  description = "Retention period in days for Azure Files backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.files_backup_retention_days >= 1 && var.files_backup_retention_days <= 9999
    error_message = "Files backup retention days must be between 1 and 9999."
  }
}

variable "files_backup_timezone" {
  description = "Timezone for Azure Files backup schedules"
  type        = string
  default     = "Romance Standard Time"
}

# ============================================================================
# BLOB BACKUP POLICY CONFIGURATION
# ============================================================================

variable "blob_backup_retention_days" {
  description = "Retention period in days for blob backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.blob_backup_retention_days >= 1 && var.blob_backup_retention_days <= 360
    error_message = "Blob backup retention days must be between 1 and 360."
  }
}

# ============================================================================
# SQL BACKUP POLICY CONFIGURATION
# ============================================================================

variable "sql_full_backup_time" {
  description = "Time for SQL full backups in UTC (HH:MM format)"
  type        = string
  default     = "18:00"
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.sql_full_backup_time))
    error_message = "SQL full backup time must be in HH:MM format (24-hour)."
  }
}

variable "sql_full_backup_retention_days" {
  description = "Retention period in days for SQL full backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.sql_full_backup_retention_days >= 7 && var.sql_full_backup_retention_days <= 9999
    error_message = "SQL full backup retention days must be between 7 and 9999."
  }
}

variable "sql_log_backup_frequency_minutes" {
  description = "Frequency in minutes for SQL log backups"
  type        = number
  default     = 60
  
  validation {
    condition     = contains([15, 30, 60, 120], var.sql_log_backup_frequency_minutes)
    error_message = "SQL log backup frequency must be 15, 30, 60, or 120 minutes."
  }
}

variable "sql_log_backup_retention_days" {
  description = "Retention period in days for SQL log backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.sql_log_backup_retention_days >= 7 && var.sql_log_backup_retention_days <= 35
    error_message = "SQL log backup retention days must be between 7 and 35."
  }
}

variable "sql_backup_compression" {
  description = "Enable compression for SQL backups"
  type        = bool
  default     = false
}

# ============================================================================
# ALERT CONFIGURATION
# ============================================================================

variable "enable_backup_alerts" {
  description = "Enable backup alert settings"
  type        = bool
  default     = true
}

variable "alert_send_to_owners" {
  description = "Send alerts to subscription owners"
  type        = string
  default     = "DoNotSend"
  
  validation {
    condition     = contains(["Send", "DoNotSend"], var.alert_send_to_owners)
    error_message = "Alert send to owners must be Send or DoNotSend."
  }
}

variable "alert_custom_email_addresses" {
  description = "List of custom email addresses for backup alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.alert_custom_email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

# ============================================================================
# ADDITIONAL CONFIGURATION VARIABLES (For Hardcoded Values)
# ============================================================================

variable "creation_method" {
  description = "Method used to create the backup resources"
  type        = string
  default     = "OpenTofu"
}

variable "backup_vault_datastore_type" {
  description = "Datastore type for backup vault"
  type        = string
  default     = "VaultStore"
  
  validation {
    condition     = contains(["VaultStore"], var.backup_vault_datastore_type)
    error_message = "Datastore type must be VaultStore."
  }
}

variable "recovery_vault_immutability" {
  description = "Immutability setting for recovery services vault"
  type        = string
  default     = "Disabled"
  
  validation {
    condition     = contains(["Enabled", "Disabled"], var.recovery_vault_immutability)
    error_message = "Immutability must be Enabled or Disabled."
  }
}

variable "vm_backup_policy_type" {
  description = "Policy type for VM backup"
  type        = string
  default     = "V1"
  
  validation {
    condition     = contains(["V1", "V2"], var.vm_backup_policy_type)
    error_message = "VM backup policy type must be V1 or V2."
  }
}

variable "vm_backup_frequency" {
  description = "Backup frequency for VM backups"
  type        = string
  default     = "Daily"
  
  validation {
    condition     = contains(["Daily"], var.vm_backup_frequency)
    error_message = "VM backup frequency must be Daily."
  }
}

variable "vm_enhanced_policy_name" {
  description = "Name for the enhanced VM backup policy"
  type        = string
  default     = "EnhancedPolicy"
}

variable "vm_enhanced_policy_type" {
  description = "Policy type for enhanced VM backup"
  type        = string
  default     = "V2"
  
  validation {
    condition     = contains(["V2"], var.vm_enhanced_policy_type)
    error_message = "Enhanced VM backup policy type must be V2."
  }
}

variable "vm_enhanced_backup_timezone" {
  description = "Timezone for enhanced VM backup schedules"
  type        = string
  default     = "UTC"
}

variable "vm_enhanced_backup_frequency" {
  description = "Backup frequency for enhanced VM backups"
  type        = string
  default     = "Hourly"
  
  validation {
    condition     = contains(["Hourly"], var.vm_enhanced_backup_frequency)
    error_message = "Enhanced VM backup frequency must be Hourly."
  }
}

variable "vm_enhanced_backup_weekdays" {
  description = "Weekdays for enhanced VM backup schedule"
  type        = list(string)
  default     = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
}

variable "files_backup_frequency" {
  description = "Backup frequency for Azure Files backups"
  type        = string
  default     = "Daily"
  
  validation {
    condition     = contains(["Daily"], var.files_backup_frequency)
    error_message = "Files backup frequency must be Daily."
  }
}

variable "sql_policy_name" {
  description = "Name for the SQL backup policy"
  type        = string
  default     = "HourlyLogBackup"
}

variable "sql_workload_type" {
  description = "Workload type for SQL backup policy"
  type        = string
  default     = "SQLDataBase"
  
  validation {
    condition     = contains(["SQLDataBase"], var.sql_workload_type)
    error_message = "SQL workload type must be SQLDataBase."
  }
}

variable "sql_backup_timezone" {
  description = "Timezone for SQL backup schedules"
  type        = string
  default     = "UTC"
}

variable "sql_full_backup_frequency" {
  description = "Backup frequency for SQL full backups"
  type        = string
  default     = "Daily"
  
  validation {
    condition     = contains(["Daily"], var.sql_full_backup_frequency)
    error_message = "SQL full backup frequency must be Daily."
  }
}

variable "sql_log_backup_policy_type" {
  description = "Policy type for SQL log backups"
  type        = string
  default     = "Log"
  
  validation {
    condition     = contains(["Log"], var.sql_log_backup_policy_type)
    error_message = "SQL log backup policy type must be Log."
  }
}

variable "sql_full_backup_policy_type" {
  description = "Policy type for SQL full backups"
  type        = string
  default     = "Full"
  
  validation {
    condition     = contains(["Full"], var.sql_full_backup_policy_type)
    error_message = "SQL full backup policy type must be Full."
  }
}

# ============================================================================
# CUSTOM BACKUP POLICIES CONFIGURATION
# ============================================================================

variable "custom_backup_policies" {
  description = "Map of custom backup policies for types not covered by predefined policies"
  type = map(object({
    # Policy type and target
    policy_type = string # "vm", "file_share", "blob_storage", "vm_workload"
    vault_type  = string # "backup_vault" or "recovery_vault"
    
    # Basic policy configuration
    name        = string
    description = optional(string, "Custom backup policy")
    
    # VM Policy specific settings (when policy_type = "vm")
    vm_policy = optional(object({
      policy_type                    = optional(string, "V1") # V1 or V2
      timezone                      = optional(string, "UTC")
      instant_restore_retention_days = optional(number, 2)
      
      # Backup schedule
      backup_frequency = string # Daily, Weekly, Hourly
      backup_time      = optional(string, "02:00")
      backup_weekdays  = optional(list(string), ["Sunday"])
      
      # For hourly backups (V2 only)
      hour_interval = optional(number, 4)
      hour_duration = optional(number, 12)
      
      # Retention settings
      daily_retention_days   = optional(number, 30)
      weekly_retention_weeks = optional(number, 0)
      monthly_retention_months = optional(number, 0)
      yearly_retention_years = optional(number, 0)
    }))
    
    # File Share Policy specific settings (when policy_type = "file_share")
    file_share_policy = optional(object({
      timezone         = optional(string, "UTC")
      backup_frequency = optional(string, "Daily")
      backup_time      = optional(string, "02:00")
      retention_days   = optional(number, 30)
    }))
    
    # Blob Storage Policy specific settings (when policy_type = "blob_storage")
    blob_policy = optional(object({
      retention_days = optional(number, 30)
    }))
    
    # VM Workload Policy specific settings (when policy_type = "vm_workload")
    vm_workload_policy = optional(object({
      workload_type       = string # SQLDataBase, SAPHanaDatabase, etc.
      timezone           = optional(string, "UTC")
      compression_enabled = optional(bool, false)
      
      # Protection policies (can have multiple)
      protection_policies = list(object({
        policy_type = string # Full, Differential, Log, Copy
        
        # Backup schedule
        backup_frequency         = optional(string, "Daily")
        backup_time             = optional(string, "02:00")
        backup_weekdays         = optional(list(string), ["Sunday"])
        frequency_in_minutes    = optional(number) # For Log backups
        
        # Retention
        retention_days   = optional(number, 30)
        retention_weeks  = optional(number, 0)
        retention_months = optional(number, 0)
        retention_years  = optional(number, 0)
      }))
    }))
    
    # Tags for the policy
    tags = optional(map(string), {})
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for k, v in var.custom_backup_policies : contains(["vm", "file_share", "blob_storage", "vm_workload"], v.policy_type)
    ])
    error_message = "Policy type must be one of: vm, file_share, blob_storage, vm_workload."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.custom_backup_policies : contains(["backup_vault", "recovery_vault"], v.vault_type)
    ])
    error_message = "Vault type must be either backup_vault or recovery_vault."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.custom_backup_policies : length(v.name) > 0 && length(v.name) <= 150
    ])
    error_message = "Custom policy name must be between 1 and 150 characters."
  }
}

# ============================================================================
# TAGGING CONFIGURATION
# ============================================================================

variable "tags" {
  description = "Tags to apply to all backup resources"
  type        = map(string)
  default     = {}
}

variable "enable_auto_tagging" {
  description = "Whether to automatically add comprehensive tags with backup metadata"
  type        = bool
  default     = true
}

# ============================================================================
# ADVANCED CONFIGURATION
# ============================================================================

variable "backup_vault_identity_type" {
  description = "Type of managed identity for backup vault"
  type        = string
  default     = "SystemAssigned"
  
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.backup_vault_identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "recovery_vault_identity_type" {
  description = "Type of managed identity for recovery services vault"
  type        = string
  default     = "SystemAssigned"
  
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.recovery_vault_identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of user assigned identity IDs for vaults"
  type        = list(string)
  default     = []
}
