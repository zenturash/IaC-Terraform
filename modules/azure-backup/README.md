# Azure Backup Services OpenTofu Module

A comprehensive OpenTofu module for deploying Azure backup services including Azure Backup Vault, Recovery Services Vault, and various backup policies. Built following generalization best practices for security-first design, minimal required input, and maximum flexibility.

## 🏗️ Features

- **Dual Vault Architecture**: Both modern Azure Backup Vault and traditional Recovery Services Vault
- **Security-First Design**: No automatic backup policies - explicit opt-in required
- **ARM Template Compliance**: All settings from ARM templates implemented as smart defaults
- **Comprehensive Policies**: VM, Files, Blobs, and SQL Server backup policies
- **Smart Defaults**: Works with minimal configuration, powerful when needed
- **Auto-Tagging**: Comprehensive metadata tagging following project patterns
- **Identity Management**: System-assigned managed identities for both vaults
- **Alert Configuration**: Configurable backup alerts and notifications

## 🚀 Quick Start

### Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- Azure subscription with appropriate permissions

### Minimal Usage (Only Required Variables)

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-prod"
}
```

**What you get:**
- Azure Backup Vault with GeoRedundant storage
- Recovery Services Vault with enhanced security
- System-assigned managed identities
- Soft delete enabled (14-day retention)
- No backup policies (security-first approach)

## 📋 Configuration Examples

### Production Backup with Policies

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-prod"
  location           = "West Europe"
  
  # Enable backup policies (security-first: explicit opt-in)
  create_backup_policies = {
    vm_daily    = true
    files_daily = true
    blob_daily  = true
  }
  
  # Customize retention periods
  vm_backup_retention_days    = 90
  files_backup_retention_days = 60
  blob_backup_retention_days  = 30
  
  # Configure alerts
  enable_backup_alerts = true
  alert_send_to_owners = "Send"
  alert_custom_email_addresses = [
    "backup-admin@company.com",
    "it-team@company.com"
  ]
  
  tags = {
    environment = "production"
    project     = "backup-infrastructure"
    cost_center = "IT-001"
  }
}
```

### Enhanced VM Backup with Hourly Snapshots

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-critical"
  
  # Enable enhanced VM backup policy
  create_backup_policies = {
    vm_enhanced = true
  }
  
  # Configure hourly backup settings
  vm_enhanced_backup_interval_hours  = 4    # Every 4 hours
  vm_enhanced_backup_window_start    = "08:00"
  vm_enhanced_backup_window_duration = 12   # 12-hour window
  
  tags = {
    environment = "production"
    criticality = "high"
  }
}
```

### SQL Server Backup Configuration

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-sql"
  
  # Enable SQL Server backup policy
  create_backup_policies = {
    sql_hourly_log = true
  }
  
  # Configure SQL backup settings
  sql_full_backup_time           = "02:00"  # 2 AM full backups
  sql_full_backup_retention_days = 90
  sql_log_backup_frequency_minutes = 15     # Log backups every 15 minutes
  sql_log_backup_retention_days  = 7
  sql_backup_compression         = true
  
  tags = {
    environment = "production"
    workload    = "database"
  }
}
```

### Multi-Policy Comprehensive Setup

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-comprehensive"
  
  # Enable all backup policies
  create_backup_policies = {
    vm_daily       = true
    vm_enhanced    = true
    files_daily    = true
    blob_daily     = true
    sql_hourly_log = true
  }
  
  # VM backup configuration
  vm_backup_time           = "01:00"
  vm_backup_retention_days = 30
  vm_backup_timezone       = "Romance Standard Time"
  
  # Enhanced VM backup configuration
  vm_enhanced_backup_interval_hours  = 6
  vm_enhanced_backup_window_start    = "08:00"
  vm_enhanced_backup_window_duration = 16
  
  # Files backup configuration
  files_backup_time           = "02:00"
  files_backup_retention_days = 60
  
  # Blob backup configuration
  blob_backup_retention_days = 90
  
  # SQL backup configuration
  sql_full_backup_time           = "03:00"
  sql_full_backup_retention_days = 90
  sql_log_backup_frequency_minutes = 30
  sql_log_backup_retention_days  = 14
  
  # Alert configuration
  enable_backup_alerts = true
  alert_send_to_owners = "Send"
  alert_custom_email_addresses = ["backup-team@company.com"]
  
  tags = {
    environment = "production"
    project     = "comprehensive-backup"
  }
}
```

## 📊 Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Name of the resource group for backup resources | `string` |

### Core Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `location` | Azure region where resources will be created | `string` | `"West Europe"` |
| `backup_vault_name` | Name of the backup vault (auto-generated if null) | `string` | `null` |
| `recovery_vault_name` | Name of the recovery services vault (auto-generated if null) | `string` | `null` |
| `create_resource_group` | Whether to create a new resource group | `bool` | `true` |

### Backup Vault Configuration (ARM Template Defaults)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `backup_vault_storage_redundancy` | Storage redundancy type | `string` | `"GeoRedundant"` |
| `backup_vault_soft_delete_state` | Soft delete state | `string` | `"On"` |
| `backup_vault_soft_delete_retention_days` | Soft delete retention period | `number` | `14` |
| `backup_vault_replicated_regions` | List of replicated regions | `list(string)` | `["northeurope"]` |

### Recovery Services Vault Configuration (ARM Template Defaults)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `recovery_vault_sku_name` | SKU name | `string` | `"RS0"` |
| `recovery_vault_sku_tier` | SKU tier | `string` | `"Standard"` |
| `recovery_vault_soft_delete_enabled` | Enable soft delete | `bool` | `true` |
| `recovery_vault_enhanced_security_state` | Enhanced security state | `string` | `"Enabled"` |
| `recovery_vault_storage_redundancy` | Storage redundancy | `string` | `"GeoRedundant"` |
| `recovery_vault_cross_region_restore` | Enable cross region restore | `bool` | `false` |
| `recovery_vault_public_network_access` | Public network access | `string` | `"Enabled"` |

### Backup Policies Configuration (Security-First - Opt-in)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_backup_policies` | Map of backup policy types to create | `object` | All `false` |

```hcl
create_backup_policies = {
  vm_daily        = false  # VM daily backup policy
  vm_enhanced     = false  # VM enhanced hourly backup policy
  files_daily     = false  # Azure Files daily backup policy
  blob_daily      = false  # Blob storage daily backup policy
  sql_hourly_log  = false  # SQL Server hourly log backup policy
}
```

### VM Backup Policy Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vm_backup_time` | Time for VM backups (HH:MM format) | `string` | `"01:00"` |
| `vm_backup_retention_days` | Retention period in days | `number` | `30` |
| `vm_backup_timezone` | Timezone for backup schedules | `string` | `"Romance Standard Time"` |
| `vm_instant_rp_retention_days` | Instant recovery point retention | `number` | `2` |

### Enhanced VM Backup Policy Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vm_enhanced_backup_interval_hours` | Backup interval in hours | `number` | `4` |
| `vm_enhanced_backup_window_start` | Backup window start time | `string` | `"08:00"` |
| `vm_enhanced_backup_window_duration` | Backup window duration in hours | `number` | `12` |

### Alert Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_backup_alerts` | Enable backup alert settings | `bool` | `true` |
| `alert_send_to_owners` | Send alerts to subscription owners | `string` | `"DoNotSend"` |
| `alert_custom_email_addresses` | List of custom email addresses | `list(string)` | `[]` |

## 📤 Outputs

### Core Vault Information

| Name | Description |
|------|-------------|
| `backup_vault_id` | ID of the Azure Backup Vault |
| `backup_vault_name` | Name of the Azure Backup Vault |
| `recovery_vault_id` | ID of the Recovery Services Vault |
| `recovery_vault_name` | Name of the Recovery Services Vault |

### Identity Information

| Name | Description |
|------|-------------|
| `backup_vault_identity` | Managed identity information for Backup Vault |
| `recovery_vault_identity` | Managed identity information for Recovery Services Vault |

### Policy Information

| Name | Description |
|------|-------------|
| `backup_policies` | Detailed information about created backup policies |
| `backup_policy_ids` | Map of backup policy names to their IDs |

### Configuration Information

| Name | Description |
|------|-------------|
| `backup_vault_configuration` | Configuration details of the Backup Vault |
| `recovery_vault_configuration` | Configuration details of the Recovery Services Vault |
| `backup_alerts_configuration` | Backup alerts configuration |

### Summary and Usage

| Name | Description |
|------|-------------|
| `backup_summary` | Comprehensive summary of the backup deployment |
| `usage_guide` | Quick guide for using the backup services |
| `vault_references` | Vault references for use in other modules |

## 🏷️ Auto-Tagging

All resources are automatically tagged with comprehensive metadata when `enable_auto_tagging = true` (default):

```hcl
tags = {
  backup_vault_name           = "backup-vault-prod"
  recovery_vault_name         = "backup-recovery-prod"
  backup_storage_redundancy   = "GeoRedundant"
  recovery_storage_redundancy = "GeoRedundant"
  creation_date              = "2025-01-16"
  creation_time              = "2025-01-16 14:32:00 CET"
  creation_method            = "OpenTofu"
  location                   = "West Europe"
  soft_delete_enabled        = "true"
  backup_retention_days      = "14"
  recovery_retention_days    = "14"
  policies_enabled           = "{\"vm_daily\":true,\"files_daily\":true}"
}
```

## 🔒 Security Considerations

### Security-First Design
- **No automatic backup policies** - All policies are opt-in via explicit configuration
- **Soft delete enabled by default** - 14-day retention for accidental deletion protection
- **Enhanced security enabled** - Advanced threat protection for Recovery Services Vault
- **System-assigned identities** - Managed identities for secure Azure service authentication

### Recommended Security Practices

```hcl
# Secure backup configuration
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-secure"
  
  # Enable only required policies
  create_backup_policies = {
    vm_daily = true  # Only enable what you need
  }
  
  # Configure secure alert settings
  enable_backup_alerts = true
  alert_send_to_owners = "Send"
  alert_custom_email_addresses = ["security-team@company.com"]
  
  # Use private network access if required
  recovery_vault_public_network_access = "Disabled"
  
  tags = {
    security_classification = "confidential"
    data_classification     = "sensitive"
  }
}
```

## 🔧 Advanced Configuration

### Custom Resource Naming

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-custom"
  
  # Custom vault names
  backup_vault_name   = "bv-prod-westeu-001"
  recovery_vault_name = "rsv-prod-westeu-001"
  
  # Custom resource naming
  resource_name_prefix = "prod-backup"
  use_random_suffix   = true  # Adds random suffix for uniqueness
}
```

### Storage Redundancy Options

```hcl
module "backup_services" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-redundancy"
  
  # Configure storage redundancy
  backup_vault_storage_redundancy   = "ZoneRedundant"  # or "LocallyRedundant"
  recovery_vault_storage_redundancy = "ZoneRedundant"  # or "LocallyRedundant"
  
  # Enable cross-region restore for geo-redundant storage
  recovery_vault_cross_region_restore = true
}
```

## 🧪 Testing

### Minimal Configuration Test

```hcl
module "backup_test_minimal" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-test-minimal"
  
  tags = {
    environment = "test"
    purpose     = "minimal-config-test"
  }
}
```

### Full Configuration Test

```hcl
module "backup_test_full" {
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-test-full"
  
  create_backup_policies = {
    vm_daily       = true
    vm_enhanced    = true
    files_daily    = true
    blob_daily     = true
    sql_hourly_log = true
  }
  
  enable_backup_alerts = true
  alert_custom_email_addresses = ["test@example.com"]
  
  tags = {
    environment = "test"
    purpose     = "full-config-test"
  }
}
```

## 🔄 Integration with Main Configuration

Add to your main configuration:

```hcl
# In variables.tf
variable "deploy_components" {
  description = "Components to deploy"
  type = object({
    backup_services = optional(bool, false)
    # ... other components
  })
}

variable "backup_configuration" {
  description = "Backup services configuration"
  type = object({
    policies = object({
      vm_daily       = optional(bool, false)
      vm_enhanced    = optional(bool, false)
      files_daily    = optional(bool, false)
      blob_daily     = optional(bool, false)
      sql_hourly_log = optional(bool, false)
    })
  })
  default = {
    policies = {}
  }
}

# In main.tf
module "backup_services" {
  count  = var.deploy_components.backup_services ? 1 : 0
  source = "./modules/azure-backup"
  
  resource_group_name = "rg-backup-${var.environment}"
  location           = var.location
  
  create_backup_policies = var.backup_configuration.policies
  
  tags = merge(local.common_tags, {
    tier = "backup"
    architecture = var.architecture_mode
  })
}
```

## 📚 ARM Template Compliance

This module implements all settings from the provided ARM template as smart defaults:

- **Backup Vault**: GeoRedundant storage, soft delete (14 days), North Europe replication
- **Recovery Services Vault**: RS0/Standard SKU, enhanced security, geo-redundant storage
- **Backup Policies**: VM Daily (30 days), Enhanced hourly, Files daily, Blob daily, SQL hourly log
- **Alert Settings**: Configurable notifications and email alerts
- **Security Settings**: Soft delete, enhanced security, cross-subscription restore

## 🚨 Important Notes

### Blob Backup Policy Portal Navigation
- **Azure Backup Vault**: Blob backup policies are located here (NOT in Recovery Services Vault)
- **Portal Path**: Resource Group → `backup-vault` → Backup policies → `Blob-Daily7`
- **Common Confusion**: Users often look in Recovery Services Vault for blob policies
- **Dual Vault Architecture**: Modern services (Blobs) use Azure Backup Vault, traditional services (VMs, Files, SQL) use Recovery Services Vault

### Recent Fix: Blob Backup Policy Outputs
**Issue Resolved (2025-01-17)**: Blob backup policy was being created correctly but not visible in OpenTofu outputs.

**Root Cause**: The `blob_daily` output was hardcoded to `null` in the module's outputs.tf file.

**Fix Applied**: 
- Updated `modules/azure-backup/outputs.tf` to properly expose blob backup policy information
- Added blob backup policy to `backup_policy_ids` mapping
- Verified policy deployment in Azure Backup Vault

**Verification**: 
```bash
# Check blob backup policy in outputs
tofu output backup_services | grep -A 10 "blob_daily"

# Expected result:
"blob_daily" = {
  "id" = "/subscriptions/.../backupPolicies/Blob-Daily7"
  "name" = "Blob-Daily7"
  "type" = "Blob Storage Daily Backup"
  "retention_days" = 7
  "vault_id" = "/subscriptions/.../backupVaults/backup-vault"
}
```

### Policy Naming Convention
- **Predictable Names**: No random suffixes (e.g., `VM-Daily30`, `Blob-Daily7`)
- **Retention Included**: Policy names include retention period for clarity
- **Type Specific**: Clear indication of backup type and schedule

### Deprecation Warnings
- **Blob Policy**: Currently uses deprecated `retention_duration` parameter
- **Future Compatibility**: Will be updated to `operational_default_retention_duration` in future versions
- **No Impact**: Functionality remains unchanged, warning can be safely ignored

## 🤝 Contributing

This module follows the principles outlined in `MODULE-GENERALIZATION-GUIDE.md`:

- **Security-First**: No automatic security rules - explicit security configuration
- **Minimal Required Input**: Only `resource_group_name` required
- **Maximum Flexibility**: Every hardcoded value is configurable
- **Progressive Complexity**: Simple by default, powerful when needed

## 📄 License

This project is provided as-is for educational and production use.
