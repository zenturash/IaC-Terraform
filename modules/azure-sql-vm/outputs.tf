# ============================================================================
# CORE SQL SERVER VM OUTPUTS
# ============================================================================

output "vm_id" {
  description = "ID of the SQL Server virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the SQL Server virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}

output "vm_size" {
  description = "Size of the SQL Server virtual machine"
  value       = azurerm_windows_virtual_machine.main.size
}

output "vm_location" {
  description = "Location of the SQL Server virtual machine"
  value       = azurerm_windows_virtual_machine.main.location
}

# ============================================================================
# AUTHENTICATION OUTPUTS
# ============================================================================

output "admin_username" {
  description = "Administrator username for the SQL Server VM"
  value       = azurerm_windows_virtual_machine.main.admin_username
}

output "admin_password" {
  description = "Administrator password for the SQL Server VM"
  value       = var.admin_password
  sensitive   = true
}

# ============================================================================
# RESOURCE GROUP OUTPUTS
# ============================================================================

output "resource_group_id" {
  description = "ID of the resource group"
  value       = local.resource_group.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group.name
}

output "resource_group_created" {
  description = "Whether the resource group was created by this module"
  value       = var.create_resource_group
}

# ============================================================================
# NETWORK OUTPUTS
# ============================================================================

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.main.id
}

output "network_interface_name" {
  description = "Name of the network interface"
  value       = azurerm_network_interface.main.name
}

output "private_ip_address" {
  description = "Private IP address of the SQL Server VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "private_ip_addresses" {
  description = "List of private IP addresses of the SQL Server VM"
  value       = azurerm_network_interface.main.private_ip_addresses
}

# ============================================================================
# PUBLIC IP OUTPUTS (CONDITIONAL)
# ============================================================================

output "public_ip_id" {
  description = "ID of the public IP address (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].id : null
}

output "public_ip_address" {
  description = "Public IP address of the SQL Server VM (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "public_ip_fqdn" {
  description = "FQDN of the public IP address (if enabled and configured)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].fqdn : null
}

output "public_ip_enabled" {
  description = "Whether public IP is enabled for this SQL Server VM"
  value       = var.enable_public_ip
}

# ============================================================================
# NETWORK SECURITY GROUP OUTPUTS (CONDITIONAL)
# ============================================================================

output "network_security_group_id" {
  description = "ID of the network security group (if created)"
  value       = var.create_nsg ? azurerm_network_security_group.main[0].id : null
}

output "network_security_group_name" {
  description = "Name of the network security group (if created)"
  value       = var.create_nsg ? azurerm_network_security_group.main[0].name : null
}

output "nsg_rules_count" {
  description = "Number of NSG rules created"
  value       = var.create_nsg ? length(local.all_nsg_rules) : 0
}

# ============================================================================
# STORAGE OUTPUTS (SQL SERVER SPECIFIC)
# ============================================================================

output "os_disk_id" {
  description = "ID of the OS disk"
  value       = azurerm_windows_virtual_machine.main.os_disk[0].name
}

output "os_disk_name" {
  description = "Name of the OS disk"
  value       = local.os_disk_name
}

output "os_disk_type" {
  description = "Storage account type of the OS disk"
  value       = var.os_disk_type
}

output "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  value       = azurerm_windows_virtual_machine.main.os_disk[0].disk_size_gb
}

# Data Disk Outputs
output "data_disk_id" {
  description = "ID of the SQL Server data disk"
  value       = azurerm_managed_disk.data_disk.id
}

output "data_disk_name" {
  description = "Name of the SQL Server data disk"
  value       = azurerm_managed_disk.data_disk.name
}

output "data_disk_size_gb" {
  description = "Size of the SQL Server data disk in GB"
  value       = azurerm_managed_disk.data_disk.disk_size_gb
}

output "data_disk_type" {
  description = "Storage account type of the SQL Server data disk"
  value       = azurerm_managed_disk.data_disk.storage_account_type
}

output "data_disk_lun" {
  description = "LUN of the SQL Server data disk"
  value       = azurerm_virtual_machine_data_disk_attachment.data_disk.lun
}

# Log Disk Outputs
output "log_disk_id" {
  description = "ID of the SQL Server log disk"
  value       = azurerm_managed_disk.log_disk.id
}

output "log_disk_name" {
  description = "Name of the SQL Server log disk"
  value       = azurerm_managed_disk.log_disk.name
}

output "log_disk_size_gb" {
  description = "Size of the SQL Server log disk in GB"
  value       = azurerm_managed_disk.log_disk.disk_size_gb
}

output "log_disk_type" {
  description = "Storage account type of the SQL Server log disk"
  value       = azurerm_managed_disk.log_disk.storage_account_type
}

output "log_disk_lun" {
  description = "LUN of the SQL Server log disk"
  value       = azurerm_virtual_machine_data_disk_attachment.log_disk.lun
}

# ============================================================================
# SQL SERVER CONFIGURATION OUTPUTS
# ============================================================================

output "sql_server_image" {
  description = "SQL Server image information"
  value = {
    publisher = local.image_publisher
    offer     = local.image_offer
    sku       = local.image_sku
    version   = var.image_version
  }
}

output "sql_server_edition" {
  description = "SQL Server edition"
  value       = var.sql_edition
}

output "sql_server_port" {
  description = "SQL Server port number"
  value       = var.sql_port
}

output "sql_connectivity_type" {
  description = "SQL Server connectivity type"
  value       = var.sql_connectivity_type
}

output "sql_authentication_type" {
  description = "SQL Server authentication type"
  value       = var.sql_authentication_type
}

# ============================================================================
# CONNECTION INFORMATION (SQL SERVER SPECIFIC)
# ============================================================================

output "rdp_connection_string" {
  description = "RDP connection string for the SQL Server VM"
  value = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
}

output "sql_connection_string" {
  description = "SQL Server connection string template"
  value = var.enable_public_ip ? "Server=${azurerm_public_ip.main[0].ip_address},${var.sql_port};Database=master;Integrated Security=false;" : "Server=${azurerm_network_interface.main.private_ip_address},${var.sql_port};Database=master;Integrated Security=false;"
}

output "sql_server_fqdn" {
  description = "SQL Server FQDN for connection"
  value = var.enable_public_ip ? (
    azurerm_public_ip.main[0].fqdn != null ? azurerm_public_ip.main[0].fqdn : azurerm_public_ip.main[0].ip_address
  ) : azurerm_network_interface.main.private_ip_address
}

# ============================================================================
# IDENTITY OUTPUTS
# ============================================================================

output "identity" {
  description = "Managed identity information"
  value = var.identity_type != "None" ? {
    type         = azurerm_windows_virtual_machine.main.identity[0].type
    principal_id = azurerm_windows_virtual_machine.main.identity[0].principal_id
    tenant_id    = azurerm_windows_virtual_machine.main.identity[0].tenant_id
  } : null
}

# ============================================================================
# COMPREHENSIVE SQL SERVER VM SUMMARY
# ============================================================================

output "sql_vm_summary" {
  description = "Comprehensive summary of the SQL Server virtual machine"
  value = {
    # Basic Information
    vm_name           = azurerm_windows_virtual_machine.main.name
    vm_id             = azurerm_windows_virtual_machine.main.id
    vm_size           = azurerm_windows_virtual_machine.main.size
    location          = azurerm_windows_virtual_machine.main.location
    resource_group    = local.resource_group.name
    
    # SQL Server Configuration
    sql_server_version     = "SQL Server 2022"
    sql_server_edition     = var.sql_edition
    sql_server_port        = var.sql_port
    sql_connectivity_type  = var.sql_connectivity_type
    sql_authentication     = var.sql_authentication_type
    sql_image              = "${local.image_publisher}/${local.image_offer}/${local.image_sku}:${var.image_version}"
    
    # Authentication
    admin_username    = azurerm_windows_virtual_machine.main.admin_username
    
    # Network Configuration
    private_ip        = azurerm_network_interface.main.private_ip_address
    public_ip         = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
    public_ip_enabled = var.enable_public_ip
    nsg_enabled       = var.create_nsg
    
    # Storage Configuration
    os_disk_name      = local.os_disk_name
    os_disk_type      = var.os_disk_type
    os_disk_size_gb   = azurerm_windows_virtual_machine.main.os_disk[0].disk_size_gb
    
    data_disk_name    = azurerm_managed_disk.data_disk.name
    data_disk_type    = azurerm_managed_disk.data_disk.storage_account_type
    data_disk_size_gb = azurerm_managed_disk.data_disk.disk_size_gb
    data_disk_lun     = azurerm_virtual_machine_data_disk_attachment.data_disk.lun
    
    log_disk_name     = azurerm_managed_disk.log_disk.name
    log_disk_type     = azurerm_managed_disk.log_disk.storage_account_type
    log_disk_size_gb  = azurerm_managed_disk.log_disk.disk_size_gb
    log_disk_lun      = azurerm_virtual_machine_data_disk_attachment.log_disk.lun
    
    # Advanced Configuration
    zone              = var.zone
    
    # Auto-generation Info
    auto_generated_resources = {
      vm_name = var.vm_name == null
    }
  }
}

# ============================================================================
# RESOURCE NAMES (FOR REFERENCE)
# ============================================================================

output "resource_names" {
  description = "Names of all created resources"
  value = {
    vm_name                = azurerm_windows_virtual_machine.main.name
    resource_group_name    = local.resource_group.name
    network_interface_name = azurerm_network_interface.main.name
    os_disk_name          = local.os_disk_name
    data_disk_name        = azurerm_managed_disk.data_disk.name
    log_disk_name         = azurerm_managed_disk.log_disk.name
    public_ip_name        = var.enable_public_ip ? azurerm_public_ip.main[0].name : null
    nsg_name              = var.create_nsg ? azurerm_network_security_group.main[0].name : null
  }
}

# ============================================================================
# SQL SERVER CONNECTION GUIDE
# ============================================================================

output "sql_connection_guide" {
  description = "Complete guide for connecting to the SQL Server VM"
  value = {
    # RDP Connection
    rdp_connection = {
      command = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
      username = azurerm_windows_virtual_machine.main.admin_username
      connection_info = var.enable_public_ip ? "Connect via public IP: ${azurerm_public_ip.main[0].ip_address}" : "Connect via private IP: ${azurerm_network_interface.main.private_ip_address} (requires VPN or bastion)"
    }
    
    # SQL Server Connection
    sql_connection = {
      server_address = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : azurerm_network_interface.main.private_ip_address
      port = var.sql_port
      connection_string = var.enable_public_ip ? "Server=${azurerm_public_ip.main[0].ip_address},${var.sql_port};Database=master;Integrated Security=false;" : "Server=${azurerm_network_interface.main.private_ip_address},${var.sql_port};Database=master;Integrated Security=false;"
      authentication_type = var.sql_authentication_type
      connectivity_type = var.sql_connectivity_type
    }
    
    # Storage Information
    storage_info = {
      data_disk = {
        name = azurerm_managed_disk.data_disk.name
        size_gb = azurerm_managed_disk.data_disk.disk_size_gb
        type = azurerm_managed_disk.data_disk.storage_account_type
        lun = azurerm_virtual_machine_data_disk_attachment.data_disk.lun
        purpose = "SQL Server Database Files (.mdf)"
        mount_instructions = "After VM deployment, initialize and format the data disk, then configure SQL Server to use it for database files"
      }
      log_disk = {
        name = azurerm_managed_disk.log_disk.name
        size_gb = azurerm_managed_disk.log_disk.disk_size_gb
        type = azurerm_managed_disk.log_disk.storage_account_type
        lun = azurerm_virtual_machine_data_disk_attachment.log_disk.lun
        purpose = "SQL Server Transaction Log Files (.ldf)"
        mount_instructions = "After VM deployment, initialize and format the log disk, then configure SQL Server to use it for transaction log files"
      }
    }
    
    # Security Information
    security_info = {
      nsg_enabled = var.create_nsg
      nsg_rules_count = var.create_nsg ? length(local.all_nsg_rules) : 0
      security_note = var.create_nsg ? "NSG is enabled - check sql_nsg_rules for specific access rules" : "No NSG configured - using subnet-level security"
      sql_port_info = "Default SQL Server port: ${var.sql_port}"
      rdp_port_info = "Default RDP port: 3389"
    }
    
    # Post-Deployment Steps
    post_deployment_steps = [
      "1. Connect to VM via RDP using the provided connection string",
      "2. Initialize and format the data disk (LUN ${azurerm_virtual_machine_data_disk_attachment.data_disk.lun}) for SQL Server database files",
      "3. Initialize and format the log disk (LUN ${azurerm_virtual_machine_data_disk_attachment.log_disk.lun}) for SQL Server transaction log files",
      "4. Configure SQL Server to use the new disks for database and log file storage",
      "5. Configure SQL Server authentication and connectivity as needed",
      "6. Test SQL Server connectivity using the provided connection string",
      "7. Configure firewall rules if using public IP access"
    ]
  }
}

# ============================================================================
# TAGS OUTPUT
# ============================================================================

output "applied_tags" {
  description = "All tags applied to the resources"
  value       = local.common_tags
}

# ============================================================================
# DISK CONFIGURATION SUMMARY
# ============================================================================

output "disk_configuration" {
  description = "Summary of all disk configurations"
  value = {
    os_disk = {
      name = local.os_disk_name
      type = var.os_disk_type
      size_gb = azurerm_windows_virtual_machine.main.os_disk[0].disk_size_gb
      caching = "ReadWrite"
      purpose = "Operating System and SQL Server Binaries"
    }
    data_disk = {
      name = azurerm_managed_disk.data_disk.name
      type = azurerm_managed_disk.data_disk.storage_account_type
      size_gb = azurerm_managed_disk.data_disk.disk_size_gb
      caching = var.data_disk_config.caching
      lun = azurerm_virtual_machine_data_disk_attachment.data_disk.lun
      purpose = "SQL Server Database Files (.mdf)"
    }
    log_disk = {
      name = azurerm_managed_disk.log_disk.name
      type = azurerm_managed_disk.log_disk.storage_account_type
      size_gb = azurerm_managed_disk.log_disk.disk_size_gb
      caching = var.log_disk_config.caching
      lun = azurerm_virtual_machine_data_disk_attachment.log_disk.lun
      purpose = "SQL Server Transaction Log Files (.ldf)"
    }
  }
}
