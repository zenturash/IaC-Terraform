# ============================================================================
# CORE VM OUTPUTS
# ============================================================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}

output "vm_size" {
  description = "Size of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.size
}

output "vm_location" {
  description = "Location of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.location
}

# ============================================================================
# AUTHENTICATION OUTPUTS
# ============================================================================

output "admin_username" {
  description = "Administrator username for the virtual machine"
  value       = azurerm_windows_virtual_machine.main.admin_username
}

output "admin_password" {
  description = "Administrator password for the virtual machine (auto-generated if not provided)"
  value       = local.admin_password
  sensitive   = true
}

output "password_auto_generated" {
  description = "Whether the admin password was auto-generated"
  value       = var.admin_password == null
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
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.main.private_ip_address
}

output "private_ip_addresses" {
  description = "List of private IP addresses of the virtual machine"
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
  description = "Public IP address of the virtual machine (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "public_ip_fqdn" {
  description = "FQDN of the public IP address (if enabled and configured)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].fqdn : null
}

output "public_ip_enabled" {
  description = "Whether public IP is enabled for this VM"
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
  description = "Number of NSG rules created (including default RDP rule)"
  value       = var.create_nsg ? length(local.all_nsg_rules) : 0
}

# ============================================================================
# STORAGE OUTPUTS
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

# ============================================================================
# VM IMAGE OUTPUTS
# ============================================================================

output "vm_image" {
  description = "VM image information"
  value = {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
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
# CONNECTION INFORMATION
# ============================================================================

output "rdp_connection_string" {
  description = "RDP connection string for the virtual machine"
  value = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
}

output "ssh_connection_string" {
  description = "SSH connection string (for reference, though this is a Windows VM)"
  value = var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "ssh ${var.admin_username}@${azurerm_network_interface.main.private_ip_address}"
}

# ============================================================================
# COMPREHENSIVE VM SUMMARY
# ============================================================================

output "vm_summary" {
  description = "Comprehensive summary of the virtual machine"
  value = {
    # Basic Information
    vm_name           = azurerm_windows_virtual_machine.main.name
    vm_id             = azurerm_windows_virtual_machine.main.id
    vm_size           = azurerm_windows_virtual_machine.main.size
    location          = azurerm_windows_virtual_machine.main.location
    resource_group    = local.resource_group.name
    
    # Authentication
    admin_username    = azurerm_windows_virtual_machine.main.admin_username
    password_auto_generated = var.admin_password == null
    
    # Network Configuration
    private_ip        = azurerm_network_interface.main.private_ip_address
    public_ip         = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
    public_ip_enabled = var.enable_public_ip
    nsg_enabled       = var.create_nsg
    
    # Storage
    os_disk_name      = local.os_disk_name
    os_disk_type      = var.os_disk_type
    os_disk_size_gb   = azurerm_windows_virtual_machine.main.os_disk[0].disk_size_gb
    
    # VM Configuration
    patch_mode        = var.patch_mode
    timezone          = var.timezone
    zone              = var.zone
    
    # Image Information
    os_image = "${var.image_publisher}/${var.image_offer}/${var.image_sku}:${var.image_version}"
    
    # Auto-generation Info
    auto_generated_resources = {
      vm_name    = var.vm_name == null
      password   = var.admin_password == null
      random_suffix = var.use_random_suffix
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
    public_ip_name        = var.enable_public_ip ? azurerm_public_ip.main[0].name : null
    nsg_name              = var.create_nsg ? azurerm_network_security_group.main[0].name : null
  }
}

# ============================================================================
# QUICK CONNECTION GUIDE
# ============================================================================

output "connection_guide" {
  description = "Quick guide for connecting to the virtual machine"
  value = {
    rdp_command = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
    
    username = azurerm_windows_virtual_machine.main.admin_username
    
    connection_info = var.enable_public_ip ? "Connect via public IP: ${azurerm_public_ip.main[0].ip_address}" : "Connect via private IP: ${azurerm_network_interface.main.private_ip_address} (requires VPN or bastion)"
    
    security_note = var.create_nsg ? "NSG is enabled - check nsg_rules for specific access rules" : "No NSG configured - using subnet-level security"
    
    password_note = var.admin_password == null ? "Password was auto-generated - check 'admin_password' output (sensitive)" : "Using provided password"
  }
}

# ============================================================================
# TAGS OUTPUT
# ============================================================================

output "applied_tags" {
  description = "All tags applied to the resources"
  value       = local.common_tags
}
