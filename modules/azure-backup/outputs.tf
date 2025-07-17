# ============================================================================
# CORE VAULT INFORMATION OUTPUTS
# ============================================================================

output "backup_vault_id" {
  description = "ID of the Azure Backup Vault"
  value       = azurerm_data_protection_backup_vault.main.id
}

output "backup_vault_name" {
  description = "Name of the Azure Backup Vault"
  value       = azurerm_data_protection_backup_vault.main.name
}

output "recovery_vault_id" {
  description = "ID of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.main.id
}

output "recovery_vault_name" {
  description = "Name of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.main.name
}

output "resource_group_name" {
  description = "Name of the resource group containing backup resources"
  value       = var.resource_group_name
}

# ============================================================================
# VAULT IDENTITY INFORMATION
# ============================================================================

output "backup_vault_identity" {
  description = "Managed identity information for the Backup Vault"
  value = {
    type         = azurerm_data_protection_backup_vault.main.identity[0].type
    principal_id = azurerm_data_protection_backup_vault.main.identity[0].principal_id
    tenant_id    = azurerm_data_protection_backup_vault.main.identity[0].tenant_id
  }
}

output "recovery_vault_identity" {
  description = "Managed identity information for the Recovery Services Vault"
  value = {
    type         = azurerm_recovery_services_vault.main.identity[0].type
    principal_id = azurerm_recovery_services_vault.main.identity[0].principal_id
    tenant_id    = azurerm_recovery_services_vault.main.identity[0].tenant_id
  }
}

# ============================================================================
# BACKUP POLICIES INFORMATION
# ============================================================================

output "backup_policies" {
  description = "Information about created backup policies"
  value = {
    vm_daily = var.create_backup_policies.vm_daily ? {
      id   = azurerm_backup_policy_vm.vm_daily[0].id
      name = azurerm_backup_policy_vm.vm_daily[0].name
      type = "VM Daily Backup"
      retention_days = var.vm_backup_retention_days
      backup_time = var.vm_backup_time
      timezone = var.vm_backup_timezone
    } : null
    
    vm_enhanced = var.create_backup_policies.vm_enhanced ? {
      id   = azurerm_backup_policy_vm.vm_enhanced[0].id
      name = azurerm_backup_policy_vm.vm_enhanced[0].name
      type = "VM Enhanced Hourly Backup"
      retention_days = var.vm_backup_retention_days
      interval_hours = var.vm_enhanced_backup_interval_hours
      window_start = var.vm_enhanced_backup_window_start
      window_duration = var.vm_enhanced_backup_window_duration
    } : null
    
    files_daily = var.create_backup_policies.files_daily ? {
      id   = azurerm_backup_policy_file_share.files_daily[0].id
      name = azurerm_backup_policy_file_share.files_daily[0].name
      type = "Azure Files Daily Backup"
      retention_days = var.files_backup_retention_days
      backup_time = var.files_backup_time
      timezone = var.files_backup_timezone
    } : null
    
    blob_daily = var.create_backup_policies.blob_daily ? {
      id   = azurerm_data_protection_backup_policy_blob_storage.blob_daily[0].id
      name = azurerm_data_protection_backup_policy_blob_storage.blob_daily[0].name
      type = "Blob Storage Daily Backup"
      retention_days = var.blob_backup_retention_days
      vault_id = azurerm_data_protection_backup_vault.main.id
    } : null
    
    sql_hourly_log = var.create_backup_policies.sql_hourly_log ? {
      id   = azurerm_backup_policy_vm_workload.sql_hourly_log[0].id
      name = azurerm_backup_policy_vm_workload.sql_hourly_log[0].name
      type = "SQL Server Hourly Log Backup"
      full_backup_time = var.sql_full_backup_time
      full_retention_days = var.sql_full_backup_retention_days
      log_frequency_minutes = var.sql_log_backup_frequency_minutes
      log_retention_days = var.sql_log_backup_retention_days
      compression_enabled = var.sql_backup_compression
    } : null
  }
}

output "backup_policy_ids" {
  description = "Map of backup policy names to their IDs"
  value = merge(
    var.create_backup_policies.vm_daily ? {
      "vm_daily" = azurerm_backup_policy_vm.vm_daily[0].id
    } : {},
    var.create_backup_policies.vm_enhanced ? {
      "vm_enhanced" = azurerm_backup_policy_vm.vm_enhanced[0].id
    } : {},
    var.create_backup_policies.files_daily ? {
      "files_daily" = azurerm_backup_policy_file_share.files_daily[0].id
    } : {},
    var.create_backup_policies.blob_daily ? {
      "blob_daily" = azurerm_data_protection_backup_policy_blob_storage.blob_daily[0].id
    } : {},
    var.create_backup_policies.sql_hourly_log ? {
      "sql_hourly_log" = azurerm_backup_policy_vm_workload.sql_hourly_log[0].id
    } : {}
  )
}

# ============================================================================
# VAULT CONFIGURATION INFORMATION
# ============================================================================

output "backup_vault_configuration" {
  description = "Configuration details of the Backup Vault"
  value = {
    name                    = azurerm_data_protection_backup_vault.main.name
    location               = azurerm_data_protection_backup_vault.main.location
    datastore_type         = azurerm_data_protection_backup_vault.main.datastore_type
    redundancy             = azurerm_data_protection_backup_vault.main.redundancy
    soft_delete_state      = var.backup_vault_soft_delete_state
    soft_delete_retention  = var.backup_vault_soft_delete_retention_days
    replicated_regions     = var.backup_vault_replicated_regions
  }
}

output "recovery_vault_configuration" {
  description = "Configuration details of the Recovery Services Vault"
  value = {
    name                           = azurerm_recovery_services_vault.main.name
    location                      = azurerm_recovery_services_vault.main.location
    sku                           = azurerm_recovery_services_vault.main.sku
    storage_mode_type             = azurerm_recovery_services_vault.main.storage_mode_type
    cross_region_restore_enabled  = azurerm_recovery_services_vault.main.cross_region_restore_enabled
    soft_delete_enabled           = azurerm_recovery_services_vault.main.soft_delete_enabled
    public_network_access_enabled = azurerm_recovery_services_vault.main.public_network_access_enabled
    enhanced_security_state       = var.recovery_vault_enhanced_security_state
    cross_subscription_restore    = var.recovery_vault_cross_subscription_restore
  }
}

# ============================================================================
# ALERT CONFIGURATION INFORMATION
# ============================================================================

output "backup_alerts_configuration" {
  description = "Backup alerts configuration"
  value = {
    enabled                = var.enable_backup_alerts
    send_to_owners        = var.alert_send_to_owners
    custom_email_addresses = var.alert_custom_email_addresses
    note                  = "Alert configuration requires manual setup via Azure Portal, CLI, or ARM templates"
  }
}

# ============================================================================
# DEPLOYMENT SUMMARY OUTPUT
# ============================================================================

output "backup_summary" {
  description = "Comprehensive summary of the backup deployment"
  value = {
    # Vault Information
    backup_vault_name    = azurerm_data_protection_backup_vault.main.name
    recovery_vault_name  = azurerm_recovery_services_vault.main.name
    resource_group_name  = var.resource_group_name
    location            = var.location
    
    # Storage Configuration
    backup_storage_redundancy   = var.backup_vault_storage_redundancy
    recovery_storage_redundancy = var.recovery_vault_storage_redundancy
    
    # Security Configuration
    soft_delete_enabled         = true
    backup_soft_delete_days     = var.backup_vault_soft_delete_retention_days
    recovery_soft_delete_days   = var.recovery_vault_soft_delete_retention_days
    enhanced_security_enabled   = var.recovery_vault_enhanced_security_state == "Enabled"
    cross_region_restore        = var.recovery_vault_cross_region_restore
    public_network_access       = var.recovery_vault_public_network_access
    
    # Policies Created
    policies_created = local.policies_created
    total_policies   = length([for k, v in local.policies_created : k if v])
    
    # Identity Configuration
    backup_vault_identity_type   = var.backup_vault_identity_type
    recovery_vault_identity_type = var.recovery_vault_identity_type
    
    # Alert Configuration
    alerts_enabled = var.enable_backup_alerts
    
    # Deployment Metadata
    auto_generated_names = {
      backup_vault  = var.backup_vault_name == null
      recovery_vault = var.recovery_vault_name == null
    }
    random_suffix_used = false
  }
}

# ============================================================================
# USAGE GUIDE OUTPUT
# ============================================================================

output "usage_guide" {
  description = "Quick guide for using the backup services"
  value = {
    backup_vault_usage = {
      description = "Use this vault for modern backup services (Blobs, Disks, etc.)"
      vault_id    = azurerm_data_protection_backup_vault.main.id
      identity_id = azurerm_data_protection_backup_vault.main.identity[0].principal_id
    }
    
    recovery_vault_usage = {
      description = "Use this vault for traditional backup services (VMs, Files, SQL)"
      vault_id    = azurerm_recovery_services_vault.main.id
      identity_id = azurerm_recovery_services_vault.main.identity[0].principal_id
    }
    
    policy_usage = {
      vm_backup = (var.create_backup_policies.vm_daily || var.create_backup_policies.vm_enhanced) ? "VM backup policies are available - configure backup items to use them" : "No VM backup policies created - enable via create_backup_policies.vm_daily or vm_enhanced"
      
      files_backup = var.create_backup_policies.files_daily ? "Azure Files backup policy is available - configure file shares to use it" : "No Files backup policy created - enable via create_backup_policies.files_daily"
      
      blob_backup = var.create_backup_policies.blob_daily ? "Blob backup policy is available - configure storage accounts to use it" : "No Blob backup policy created - enable via create_backup_policies.blob_daily"
      
      sql_backup = var.create_backup_policies.sql_hourly_log ? "SQL Server backup policy is available - configure SQL workloads to use it" : "No SQL backup policy created - enable via create_backup_policies.sql_hourly_log"
    }
    
    next_steps = [
      "Configure backup items to use the created policies",
      "Set up monitoring and alerting for backup jobs",
      "Test restore procedures for critical workloads",
      "Review and adjust retention policies as needed"
    ]
  }
}

# ============================================================================
# RESOURCE REFERENCES FOR INTEGRATION
# ============================================================================

output "vault_references" {
  description = "Vault references for use in other modules or configurations"
  value = {
    backup_vault = {
      id                  = azurerm_data_protection_backup_vault.main.id
      name               = azurerm_data_protection_backup_vault.main.name
      resource_group_name = azurerm_data_protection_backup_vault.main.resource_group_name
      location           = azurerm_data_protection_backup_vault.main.location
      principal_id       = azurerm_data_protection_backup_vault.main.identity[0].principal_id
    }
    
    recovery_vault = {
      id                  = azurerm_recovery_services_vault.main.id
      name               = azurerm_recovery_services_vault.main.name
      resource_group_name = azurerm_recovery_services_vault.main.resource_group_name
      location           = azurerm_recovery_services_vault.main.location
      principal_id       = azurerm_recovery_services_vault.main.identity[0].principal_id
    }
  }
}
