# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Random ID for unique resource naming (if enabled)
resource "random_id" "main" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
}

# Local values for resource naming and configuration
locals {
  # Generate unique suffix for resource names
  random_suffix = var.use_random_suffix ? random_id.main[0].hex : ""
  suffix = var.use_random_suffix ? "-${local.random_suffix}" : ""
  
  # Determine resource names (auto-generate if not provided)
  backup_vault_name = var.backup_vault_name != null ? var.backup_vault_name : "${var.resource_name_prefix}-vault${local.suffix}"
  recovery_vault_name = var.recovery_vault_name != null ? var.recovery_vault_name : "${var.resource_name_prefix}-recovery${local.suffix}"
  
  # Comprehensive tagging following project patterns
  base_tags = var.enable_auto_tagging ? {
    backup_vault_name           = local.backup_vault_name
    recovery_vault_name         = local.recovery_vault_name
    backup_storage_redundancy   = var.backup_vault_storage_redundancy
    recovery_storage_redundancy = var.recovery_vault_storage_redundancy
    creation_date              = formatdate("YYYY-MM-DD", timestamp())
    creation_time              = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method            = "OpenTofu"
    location                   = var.location
    soft_delete_enabled        = "true"
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
  datastore_type      = "VaultStore"
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
  immutability                     = "Disabled"  # Default from ARM
  
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
resource "azurerm_data_protection_backup_policy_blob_storage" "blob_daily" {
  count    = var.create_backup_policies.blob_daily ? 1 : 0
  name     = "Blob-Daily${var.blob_backup_retention_days}"
  vault_id = azurerm_data_protection_backup_vault.main.id
  
  # Retention configuration from ARM template
  retention_duration = "P${var.blob_backup_retention_days}D"
  
  depends_on = [azurerm_data_protection_backup_vault.main]
}

# ============================================================================
# RECOVERY SERVICES VAULT BACKUP POLICIES
# ============================================================================

# VM Daily Backup Policy (Standard V1 Policy)
resource "azurerm_backup_policy_vm" "vm_daily" {
  count               = var.create_backup_policies.vm_daily ? 1 : 0
  name                = "VM-Daily${var.vm_backup_retention_days}"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  
  # Policy type V1 (from ARM template)
  policy_type = "V1"
  
  # Timezone configuration from ARM template
  timezone = var.vm_backup_timezone
  
  # Backup schedule configuration
  backup {
    frequency = "Daily"
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

resource "azurerm_backup_vault_notification" "main" {
  count               = var.enable_backup_alerts ? 1 : 0
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  
  # Alert configuration from ARM template
  notifications_enabled    = true
  send_to_owners          = var.alert_send_to_owners == "Send"
  custom_email_addresses  = var.alert_custom_email_addresses
  
  depends_on = [azurerm_recovery_services_vault.main]
}

# ============================================================================
# RECOVERY SERVICES VAULT SETTINGS
# ============================================================================

# Note: Some vault settings like replicationVaultSettings and enhanced security
# are configured through the main vault resource properties above.
# Additional settings can be added here as needed for specific requirements.
