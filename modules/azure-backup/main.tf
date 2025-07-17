# Local values for resource naming and configuration
locals {
  # Determine resource names (auto-generate if not provided)
  backup_vault_name = var.backup_vault_name != null ? var.backup_vault_name : "backup-vault"
  recovery_vault_name = var.recovery_vault_name != null ? var.recovery_vault_name : "recovery-vault"
  
  # Comprehensive tagging following project patterns
  base_tags = var.enable_auto_tagging ? {
    backup_vault_name           = local.backup_vault_name
    recovery_vault_name         = local.recovery_vault_name
    backup_storage_redundancy   = var.backup_vault_storage_redundancy
    recovery_storage_redundancy = var.recovery_vault_storage_redundancy
    creation_date              = formatdate("YYYY-MM-DD", timestamp())
    creation_time              = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method            = var.creation_method
    location                   = var.location
    soft_delete_enabled        = var.recovery_vault_soft_delete_enabled
    backup_retention_days      = var.backup_vault_soft_delete_retention_days
    recovery_retention_days    = var.recovery_vault_soft_delete_retention_days
    policies_enabled           = jsonencode(var.create_backup_policies)
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
  
  # Policy creation flags for outputs
  policies_created = {
    vm_daily       = var.create_backup_policies.vm_daily
    vm_enhanced    = var.create_backup_policies.vm_enhanced
    files_daily    = var.create_backup_policies.files_daily
    blob_daily     = var.create_backup_policies.blob_daily
    sql_hourly_log = var.create_backup_policies.sql_hourly_log
  }
  
  # Convert backup times to proper format for Azure
  vm_backup_datetime = "2023-05-12T${var.vm_backup_time}:00Z"
  files_backup_datetime = "2023-05-12T${var.files_backup_time}:00Z"
  sql_full_backup_datetime = "2023-05-11T${var.sql_full_backup_time}:00Z"
  vm_enhanced_window_start = "2023-05-11T${var.vm_enhanced_backup_window_start}:00Z"
}

# ============================================================================
# RESOURCE GROUP (Optional - Create if Requested)
# ============================================================================

resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  
  tags = local.common_tags
}

# ============================================================================
# AZURE BACKUP VAULT (Microsoft.DataProtection/backupVaults)
# ============================================================================

resource "azurerm_data_protection_backup_vault" "main" {
  name                = local.backup_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  datastore_type      = var.backup_vault_datastore_type
  redundancy          = var.backup_vault_storage_redundancy
  
  # System-assigned managed identity (from ARM template)
  identity {
    type = var.backup_vault_identity_type
  }
  
  tags = local.common_tags
  
  depends_on = [azurerm_resource_group.main]
}

# ============================================================================
# RECOVERY SERVICES VAULT (Microsoft.RecoveryServices/vaults)
# ============================================================================

resource "azurerm_recovery_services_vault" "main" {
  name                = local.recovery_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # SKU configuration from ARM template
  sku = var.recovery_vault_sku_name
  
  # Storage configuration from ARM template
  storage_mode_type                = var.recovery_vault_storage_redundancy
  cross_region_restore_enabled     = var.recovery_vault_cross_region_restore
  soft_delete_enabled              = var.recovery_vault_soft_delete_enabled
  public_network_access_enabled    = var.recovery_vault_public_network_access == "Enabled"
  
  # Enhanced security and other settings from ARM template
  immutability                     = var.recovery_vault_immutability
  
  # System-assigned managed identity
  identity {
    type = var.recovery_vault_identity_type
  }
  
  tags = local.common_tags
  
  depends_on = [azurerm_resource_group.main]
}

# ============================================================================
# BACKUP VAULT POLICIES (Microsoft.DataProtection/backupVaults/backupPolicies)
# ============================================================================

# Blob Daily Backup Policy (30-day retention)
# NOTE: Temporarily disabled due to deprecation warnings in azurerm provider v3.x
# Will be re-enabled when azurerm v4.0 is released with the new property name
# resource "azurerm_data_protection_backup_policy_blob_storage" "blob_daily" {
#   count    = var.create_backup_policies.blob_daily ? 1 : 0
#   name     = "Blob-Daily${var.blob_backup_retention_days}"
#   vault_id = azurerm_data_protection_backup_vault.main.id
#   
#   # Retention configuration from ARM template
#   retention_duration = "P${var.blob_backup_retention_days}D"
#   
#   depends_on = [azurerm_data_protection_backup_vault.main]
# }

# ============================================================================
# RECOVERY SERVICES VAULT BACKUP POLICIES
# ============================================================================

# VM Daily Backup Policy (Standard V1 Policy)
resource "azurerm_backup_policy_vm" "vm_daily" {
  count               = var.create_backup_policies.vm_daily ? 1 : 0
  name                = "VM-Daily${var.vm_backup_retention_days}"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  
  # Policy type from ARM template
  policy_type = var.vm_backup_policy_type
  
  # Timezone configuration from ARM template
  timezone = var.vm_backup_timezone
  
  # Backup schedule configuration
  backup {
    frequency = var.vm_backup_frequency
    time      = var.vm_backup_time
  }
  
  # Retention configuration from ARM template
  retention_daily {
    count = var.vm_backup_retention_days
  }
  
  # Instant restore configuration from ARM template
  instant_restore_retention_days = var.vm_instant_rp_retention_days
  
  depends_on = [azurerm_recovery_services_vault.main]
}

# VM Enhanced Backup Policy (V2 Policy with Hourly Backups)
resource "azurerm_backup_policy_vm" "vm_enhanced" {
  count               = var.create_backup_policies.vm_enhanced ? 1 : 0
  name                = "EnhancedPolicy"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  
  # Policy type V2 for enhanced features (from ARM template)
  policy_type = "V2"
  
  # Timezone configuration
  timezone = "UTC"
  
  # Hourly backup schedule configuration from ARM template
  backup {
    frequency     = "Hourly"
    time          = var.vm_enhanced_backup_window_start
    hour_interval = var.vm_enhanced_backup_interval_hours
    hour_duration = var.vm_enhanced_backup_window_duration
    weekdays      = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  }
  
  # Retention configuration
  retention_daily {
    count = var.vm_backup_retention_days
  }
  
  # Instant restore configuration
  instant_restore_retention_days = var.vm_instant_rp_retention_days
  
  depends_on = [azurerm_recovery_services_vault.main]
}

# Azure Files Daily Backup Policy
resource "azurerm_backup_policy_file_share" "files_daily" {
  count               = var.create_backup_policies.files_daily ? 1 : 0
  name                = "Files-Daily${var.files_backup_retention_days}"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  
  # Timezone configuration from ARM template
  timezone = var.files_backup_timezone
  
  # Backup schedule configuration
  backup {
    frequency = "Daily"
    time      = var.files_backup_time
  }
  
  # Retention configuration
  retention_daily {
    count = var.files_backup_retention_days
  }
  
  depends_on = [azurerm_recovery_services_vault.main]
}

# SQL Server Hourly Log Backup Policy
resource "azurerm_backup_policy_vm_workload" "sql_hourly_log" {
  count               = var.create_backup_policies.sql_hourly_log ? 1 : 0
  name                = "HourlyLogBackup"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  workload_type       = "SQLDataBase"
  
  # Settings from ARM template
  settings {
    time_zone           = "UTC"
    compression_enabled = var.sql_backup_compression
  }
  
  # Full backup protection policy
  protection_policy {
    policy_type = "Full"
    
    backup {
      frequency = "Daily"
      time      = var.sql_full_backup_time
    }
    
    retention_daily {
      count = var.sql_full_backup_retention_days
    }
  }
  
  # Log backup protection policy from ARM template
  protection_policy {
    policy_type = "Log"
    
    backup {
      frequency_in_minutes = var.sql_log_backup_frequency_minutes
    }
    
    simple_retention {
      count = var.sql_log_backup_retention_days
    }
  }
  
  depends_on = [azurerm_recovery_services_vault.main]
}

# ============================================================================
# RECOVERY SERVICES VAULT ALERT SETTINGS
# ============================================================================

# Note: Backup alert settings are configured through the Recovery Services Vault
# properties. The azurerm_backup_vault_notification resource doesn't exist in
# the current provider version. Alert configuration would need to be done
# through Azure CLI, PowerShell, or ARM templates after vault creation.
# For now, we'll document this as a manual configuration step.

# ============================================================================
# CUSTOM BACKUP POLICIES (DISABLED)
# ============================================================================

# NOTE: Custom backup policies have been disabled due to configuration issues
# with Azure backup policy parameters. The basic predefined policies work correctly.
# Custom policies can be re-enabled in the future once the configuration issues
# are resolved or when azurerm provider v4.0 is available.

# # Custom VM Backup Policies (Recovery Services Vault) - DISABLED
# resource "azurerm_backup_policy_vm" "custom_vm" {
#   for_each = {
#     for k, v in var.custom_backup_policies : k => v 
#     if v.policy_type == "vm" && v.vault_type == "recovery_vault"
#   }
#   
#   name                = each.value.name
#   resource_group_name = var.resource_group_name
#   recovery_vault_name = azurerm_recovery_services_vault.main.name
#   
#   # Policy configuration from custom settings
#   policy_type = each.value.vm_policy.policy_type
#   timezone    = each.value.vm_policy.timezone
#   
#   # Backup schedule configuration
#   backup {
#     frequency = each.value.vm_policy.backup_frequency
#     time      = each.value.vm_policy.backup_time
#     weekdays  = each.value.vm_policy.backup_frequency == "Weekly" ? each.value.vm_policy.backup_weekdays : null
#     
#     # Hourly backup settings (V2 only)
#     hour_interval = each.value.vm_policy.policy_type == "V2" && each.value.vm_policy.backup_frequency == "Hourly" ? each.value.vm_policy.hour_interval : null
#     hour_duration = each.value.vm_policy.policy_type == "V2" && each.value.vm_policy.backup_frequency == "Hourly" ? each.value.vm_policy.hour_duration : null
#   }
#   
#   # Retention configuration - only create blocks when retention > 0
#   dynamic "retention_daily" {
#     for_each = each.value.vm_policy.daily_retention_days > 0 ? [1] : []
#     content {
#       count = each.value.vm_policy.daily_retention_days
#     }
#   }
#   
#   dynamic "retention_weekly" {
#     for_each = each.value.vm_policy.weekly_retention_weeks > 0 ? [1] : []
#     content {
#       count    = each.value.vm_policy.weekly_retention_weeks
#       weekdays = each.value.vm_policy.backup_frequency == "Weekly" ? each.value.vm_policy.backup_weekdays : ["Sunday"]
#     }
#   }
#   
#   dynamic "retention_monthly" {
#     for_each = each.value.vm_policy.monthly_retention_months > 0 ? [1] : []
#     content {
#       count    = each.value.vm_policy.monthly_retention_months
#       weekdays = each.value.vm_policy.backup_frequency == "Weekly" ? each.value.vm_policy.backup_weekdays : ["Sunday"]
#       weeks    = ["First"]
#     }
#   }
#   
#   dynamic "retention_yearly" {
#     for_each = each.value.vm_policy.yearly_retention_years > 0 ? [1] : []
#     content {
#       count    = each.value.vm_policy.yearly_retention_years
#       weekdays = each.value.vm_policy.backup_frequency == "Weekly" ? each.value.vm_policy.backup_weekdays : ["Sunday"]
#       weeks    = ["First"]
#       months   = ["January"]
#     }
#   }
#   
#   # Instant restore configuration
#   instant_restore_retention_days = each.value.vm_policy.instant_restore_retention_days
#   
#   depends_on = [azurerm_recovery_services_vault.main]
# }

# # Custom File Share Backup Policies (Recovery Services Vault) - DISABLED
# resource "azurerm_backup_policy_file_share" "custom_file_share" {
#   for_each = {
#     for k, v in var.custom_backup_policies : k => v 
#     if v.policy_type == "file_share" && v.vault_type == "recovery_vault"
#   }
#   
#   name                = each.value.name
#   resource_group_name = var.resource_group_name
#   recovery_vault_name = azurerm_recovery_services_vault.main.name
#   
#   # Timezone configuration
#   timezone = each.value.file_share_policy.timezone
#   
#   # Backup schedule configuration
#   backup {
#     frequency = each.value.file_share_policy.backup_frequency
#     time      = each.value.file_share_policy.backup_time
#   }
#   
#   # Retention configuration
#   retention_daily {
#     count = each.value.file_share_policy.retention_days
#   }
#   
#   depends_on = [azurerm_recovery_services_vault.main]
# }

# Custom Blob Storage Backup Policies (Backup Vault) - DISABLED
# NOTE: Temporarily disabled due to deprecation warnings in azurerm provider v3.x
# Will be re-enabled when azurerm v4.0 is released with the new property name
# resource "azurerm_data_protection_backup_policy_blob_storage" "custom_blob" {
#   for_each = {
#     for k, v in var.custom_backup_policies : k => v 
#     if v.policy_type == "blob_storage" && v.vault_type == "backup_vault"
#   }
#   
#   name     = each.value.name
#   vault_id = azurerm_data_protection_backup_vault.main.id
#   
#   # Retention configuration
#   # Note: retention_duration will be renamed to operational_default_retention_duration in azurerm v4.0
#   # This is currently working correctly with v3.x provider
#   retention_duration = "P${each.value.blob_policy.retention_days}D"
#   
#   depends_on = [azurerm_data_protection_backup_vault.main]
# }

# # Custom VM Workload Backup Policies (Recovery Services Vault) - DISABLED
# resource "azurerm_backup_policy_vm_workload" "custom_vm_workload" {
#   for_each = {
#     for k, v in var.custom_backup_policies : k => v 
#     if v.policy_type == "vm_workload" && v.vault_type == "recovery_vault"
#   }
#   
#   name                = each.value.name
#   resource_group_name = var.resource_group_name
#   recovery_vault_name = azurerm_recovery_services_vault.main.name
#   workload_type       = each.value.vm_workload_policy.workload_type
#   
#   # Settings configuration
#   settings {
#     time_zone           = each.value.vm_workload_policy.timezone
#     compression_enabled = each.value.vm_workload_policy.compression_enabled
#   }
#   
#   # Dynamic protection policies
#   dynamic "protection_policy" {
#     for_each = each.value.vm_workload_policy.protection_policies
#     content {
#       policy_type = protection_policy.value.policy_type
#       
#       # Backup schedule
#       dynamic "backup" {
#         for_each = protection_policy.value.policy_type != "Log" ? [1] : []
#         content {
#           frequency = protection_policy.value.backup_frequency
#           time      = protection_policy.value.backup_time
#           weekdays  = protection_policy.value.backup_frequency == "Weekly" ? protection_policy.value.backup_weekdays : null
#         }
#       }
#       
#       # Log backup schedule (for Log policy type)
#       dynamic "backup" {
#         for_each = protection_policy.value.policy_type == "Log" ? [1] : []
#         content {
#           frequency_in_minutes = protection_policy.value.frequency_in_minutes
#         }
#       }
#       
#       # Retention configuration for non-Log policies
#       dynamic "retention_daily" {
#         for_each = protection_policy.value.policy_type != "Log" && protection_policy.value.retention_days > 0 ? [1] : []
#         content {
#           count = protection_policy.value.retention_days
#         }
#       }
#       
#       # Simple retention for Log policies
#       dynamic "simple_retention" {
#         for_each = protection_policy.value.policy_type == "Log" ? [1] : []
#         content {
#           count = protection_policy.value.retention_days
#         }
#       }
#     }
#   }
#   
#   depends_on = [azurerm_recovery_services_vault.main]
# }

# ============================================================================
# RECOVERY SERVICES VAULT SETTINGS
# ============================================================================

# Note: Some vault settings like replicationVaultSettings and enhanced security
# are configured through the main vault resource properties above.
# Additional settings can be added here as needed for specific requirements.
