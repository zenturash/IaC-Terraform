# ============================================================================
# CORE VM OUTPUTS (OS-AGNOSTIC)
# ============================================================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].id : azurerm_linux_virtual_machine.main[0].id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].name : azurerm_linux_virtual_machine.main[0].name
}

output "vm_size" {
  description = "Size of the virtual machine"
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].size : azurerm_linux_virtual_machine.main[0].size
}

output "vm_location" {
  description = "Location of the virtual machine"
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].location : azurerm_linux_virtual_machine.main[0].location
}

output "os_type" {
  description = "Operating system type of the virtual machine"
  value       = var.os_type
}

# ============================================================================
# AUTHENTICATION OUTPUTS (OS-AWARE)
# ============================================================================

output "admin_username" {
  description = "Administrator username for the virtual machine"
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].admin_username : azurerm_linux_virtual_machine.main[0].admin_username
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

output "ssh_public_key_provided" {
  description = "Whether SSH public key was provided (Linux VMs only)"
  value       = var.os_type == "Linux" ? var.ssh_public_key != null : null
}

output "authentication_method" {
  description = "Authentication method used for the VM"
  value = var.os_type == "Windows" ? "Password" : (
    var.ssh_public_key != null && var.disable_password_authentication ? "SSH Key Only" :
    var.ssh_public_key != null && !var.disable_password_authentication ? "SSH Key + Password" :
    "Password Only"
  )
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
  description = "Number of NSG rules created"
  value       = var.create_nsg ? length(local.all_nsg_rules) : 0
}

# ============================================================================
# STORAGE OUTPUTS (OS-AGNOSTIC)
# ============================================================================

output "os_disk_id" {
  description = "ID of the OS disk"
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].os_disk[0].name : azurerm_linux_virtual_machine.main[0].os_disk[0].name
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
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].os_disk[0].disk_size_gb : azurerm_linux_virtual_machine.main[0].os_disk[0].disk_size_gb
}

# ============================================================================
# VM IMAGE OUTPUTS (OS-AWARE)
# ============================================================================

output "vm_image" {
  description = "VM image information"
  value = {
    publisher = local.image_publisher
    offer     = local.image_offer
    sku       = local.image_sku
    version   = var.image_version
  }
}

# ============================================================================
# IDENTITY OUTPUTS (OS-AGNOSTIC)
# ============================================================================

output "identity" {
  description = "Managed identity information"
  value = var.identity_type != "None" ? {
    type         = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].identity[0].type : azurerm_linux_virtual_machine.main[0].identity[0].type
    principal_id = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].identity[0].principal_id : azurerm_linux_virtual_machine.main[0].identity[0].principal_id
    tenant_id    = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].identity[0].tenant_id : azurerm_linux_virtual_machine.main[0].identity[0].tenant_id
  } : null
}

# ============================================================================
# CONNECTION INFORMATION (OS-AWARE)
# ============================================================================

output "rdp_connection_string" {
  description = "RDP connection string for Windows VMs"
  value = var.os_type == "Windows" ? (
    var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
  ) : null
}

output "ssh_connection_string" {
  description = "SSH connection string for Linux VMs"
  value = var.os_type == "Linux" ? (
    var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "ssh ${var.admin_username}@${azurerm_network_interface.main.private_ip_address}"
  ) : null
}

output "connection_command" {
  description = "OS-appropriate connection command"
  value = var.os_type == "Windows" ? (
    var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
  ) : (
    var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "ssh ${var.admin_username}@${azurerm_network_interface.main.private_ip_address}"
  )
}

# ============================================================================
# COMPREHENSIVE VM SUMMARY (OS-AWARE)
# ============================================================================

output "vm_summary" {
  description = "Comprehensive summary of the virtual machine"
  value = {
    # Basic Information
    vm_name           = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].name : azurerm_linux_virtual_machine.main[0].name
    vm_id             = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].id : azurerm_linux_virtual_machine.main[0].id
    vm_size           = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].size : azurerm_linux_virtual_machine.main[0].size
    os_type           = var.os_type
    location          = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].location : azurerm_linux_virtual_machine.main[0].location
    resource_group    = local.resource_group.name
    
    # Authentication
    admin_username    = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].admin_username : azurerm_linux_virtual_machine.main[0].admin_username
    auth_method       = var.os_type == "Windows" ? "Password" : (
      var.ssh_public_key != null && var.disable_password_authentication ? "SSH Key Only" :
      var.ssh_public_key != null && !var.disable_password_authentication ? "SSH Key + Password" :
      "Password Only"
    )
    password_auto_generated = var.admin_password == null
    
    # Network Configuration
    private_ip        = azurerm_network_interface.main.private_ip_address
    public_ip         = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
    public_ip_enabled = var.enable_public_ip
    nsg_enabled       = var.create_nsg
    
    # Storage
    os_disk_name      = local.os_disk_name
    os_disk_type      = var.os_disk_type
    os_disk_size_gb   = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].os_disk[0].disk_size_gb : azurerm_linux_virtual_machine.main[0].os_disk[0].disk_size_gb
    
    # OS-Specific Configuration
    patch_mode        = var.os_type == "Windows" ? var.patch_mode : null
    timezone          = var.os_type == "Windows" ? var.timezone : null
    zone              = var.zone
    
    # Image Information
    os_image = "${local.image_publisher}/${local.image_offer}/${local.image_sku}:${var.image_version}"
    
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
    vm_name                = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].name : azurerm_linux_virtual_machine.main[0].name
    resource_group_name    = local.resource_group.name
    network_interface_name = azurerm_network_interface.main.name
    os_disk_name          = local.os_disk_name
    public_ip_name        = var.enable_public_ip ? azurerm_public_ip.main[0].name : null
    nsg_name              = var.create_nsg ? azurerm_network_security_group.main[0].name : null
  }
}

# ============================================================================
# QUICK CONNECTION GUIDE (OS-AWARE)
# ============================================================================

output "connection_guide" {
  description = "Quick guide for connecting to the virtual machine"
  value = {
    os_type = var.os_type
    
    connection_method = var.os_type == "Windows" ? "RDP" : "SSH"
    
    connection_command = var.os_type == "Windows" ? (
      var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
    ) : (
      var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "ssh ${var.admin_username}@${azurerm_network_interface.main.private_ip_address}"
    )
    
    username = var.os_type == "Windows" ? azurerm_windows_virtual_machine.main[0].admin_username : azurerm_linux_virtual_machine.main[0].admin_username
    
    connection_info = var.enable_public_ip ? "Connect via public IP: ${azurerm_public_ip.main[0].ip_address}" : "Connect via private IP: ${azurerm_network_interface.main.private_ip_address} (requires VPN or bastion)"
    
    auth_info = var.os_type == "Windows" ? (
      var.admin_password == null ? "Password was auto-generated - check 'admin_password' output (sensitive)" : "Using provided password"
    ) : (
      var.ssh_public_key != null && var.disable_password_authentication ? "SSH key authentication only" :
      var.ssh_public_key != null && !var.disable_password_authentication ? "SSH key + password authentication available" :
      var.admin_password == null ? "Password was auto-generated - check 'admin_password' output (sensitive)" : "Using provided password"
    )
    
    security_note = var.create_nsg ? "NSG is enabled - check nsg_rules for specific access rules" : "No NSG configured - using subnet-level security"
    
    port_info = var.os_type == "Windows" ? "Default RDP port: 3389" : "Default SSH port: 22"
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
# LINUX-SPECIFIC OUTPUTS
# ============================================================================

output "linux_config" {
  description = "Linux-specific configuration (null for Windows VMs)"
  value = var.os_type == "Linux" ? {
    disable_password_authentication = var.disable_password_authentication
    ssh_key_provided               = var.ssh_public_key != null
    password_auth_available        = !var.disable_password_authentication
  } : null
}

# ============================================================================
# WINDOWS-SPECIFIC OUTPUTS
# ============================================================================

output "windows_config" {
  description = "Windows-specific configuration (null for Linux VMs)"
  value = var.os_type == "Windows" ? {
    patch_mode              = var.patch_mode
    hotpatching_enabled     = var.hotpatching_enabled
    timezone                = var.timezone
    enable_automatic_updates = var.enable_automatic_updates
  } : null
}
