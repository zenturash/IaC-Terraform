# ============================================================================
# RANDOM RESOURCES FOR AUTO-GENERATION
# ============================================================================

# Random ID for unique resource naming
resource "random_id" "main" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
}

# No auto-generation - users must provide credentials explicitly

# ============================================================================
# LOCAL VALUES FOR CONSISTENT NAMING AND CONFIGURATION
# ============================================================================

locals {
  # Generate unique suffix for resource names
  random_suffix = var.use_random_suffix ? random_id.main[0].hex : ""
  suffix = var.use_random_suffix ? "-${local.random_suffix}" : ""
  
  # Determine VM name (auto-generate if not provided)
  vm_name = var.vm_name != null ? var.vm_name : "vm${local.suffix}"
  
  # Use provided admin password directly
  admin_password = var.admin_password
  
  # Resource names with prefixes and suffixes
  public_ip_name = "${var.public_ip_name_prefix}-${local.vm_name}"
  nsg_name       = "${var.nsg_name_prefix}-${local.vm_name}"
  nic_name       = "${var.nic_name_prefix}-${local.vm_name}"
  os_disk_name   = var.os_disk_name != null ? var.os_disk_name : "osdisk-${local.vm_name}"
  
  # Resource group name with suffix if creating new RG
  resource_group_name = var.create_resource_group ? "${var.resource_group_name}${local.suffix}" : var.resource_group_name
  
  # OS-specific image defaults
  os_image_defaults = {
    Windows = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2025-datacenter-azure-edition"
    }
    Linux = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
    }
  }
  
  # Determine image configuration (use provided or OS defaults)
  image_publisher = var.image_publisher != "MicrosoftWindowsServer" ? var.image_publisher : local.os_image_defaults[var.os_type].publisher
  image_offer     = var.image_offer != "WindowsServer" ? var.image_offer : local.os_image_defaults[var.os_type].offer
  image_sku       = var.image_sku != "2025-datacenter-azure-edition" ? var.image_sku : local.os_image_defaults[var.os_type].sku
  
  # Connection IP for outputs
  connection_ip = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : azurerm_network_interface.main.private_ip_address
  
  # Comprehensive tagging
  base_tags = var.enable_auto_tagging ? {
    vm_name           = local.vm_name
    vm_size           = var.vm_size
    os_type           = var.os_type
    os_image          = "${local.image_publisher}-${local.image_offer}-${local.image_sku}"
    os_disk_type      = var.os_disk_type
    creation_date     = formatdate("YYYY-MM-DD", timestamp())
    creation_time     = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method   = "OpenTofu"
    admin_username    = var.admin_username
    location          = var.location
    public_ip_enabled = var.enable_public_ip
    auto_generated    = var.vm_name == null || var.admin_password == null
    auth_method       = var.os_type == "Linux" ? (var.ssh_public_key != null ? "SSH" : "Password") : "Password"
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
  
  # NSG rules are only the ones explicitly defined by the user
  all_nsg_rules = var.nsg_rules
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

# Data source for existing resource group (when not creating new one)
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Create new resource group (conditional)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Local reference to resource group (existing or created)
locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.main[0] : data.azurerm_resource_group.existing[0]
}

# ============================================================================
# PUBLIC IP (CONDITIONAL)
# ============================================================================

resource "azurerm_public_ip" "main" {
  count               = var.enable_public_ip ? 1 : 0
  name                = local.public_ip_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  zones               = var.zone != null ? [var.zone] : null
  tags                = local.common_tags
}

# ============================================================================
# NETWORK SECURITY GROUP (CONDITIONAL - INDEPENDENT OF PUBLIC IP)
# ============================================================================

resource "azurerm_network_security_group" "main" {
  count               = var.create_nsg ? 1 : 0
  name                = local.nsg_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  tags                = local.common_tags
}

# NSG Rules (default RDP + custom rules)
resource "azurerm_network_security_rule" "rules" {
  count = var.create_nsg ? length(local.all_nsg_rules) : 0
  
  name                        = local.all_nsg_rules[count.index].name
  priority                    = local.all_nsg_rules[count.index].priority
  direction                   = local.all_nsg_rules[count.index].direction
  access                      = local.all_nsg_rules[count.index].access
  protocol                    = local.all_nsg_rules[count.index].protocol
  source_port_range           = local.all_nsg_rules[count.index].source_port_range
  destination_port_range      = local.all_nsg_rules[count.index].destination_port_range
  source_address_prefix       = local.all_nsg_rules[count.index].source_address_prefix
  destination_address_prefix  = local.all_nsg_rules[count.index].destination_address_prefix
  resource_group_name         = local.resource_group.name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

# ============================================================================
# NETWORK INTERFACE
# ============================================================================

resource "azurerm_network_interface" "main" {
  name                = local.nic_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  tags                = local.common_tags

  ip_configuration {
    name                          = var.nic_ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_allocation
    private_ip_address            = var.private_ip_allocation == "Static" ? var.private_ip_address : null
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.main[0].id : null
  }
}

# Associate NSG with Network Interface (conditional - independent of public IP)
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.create_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

# ============================================================================
# VIRTUAL MACHINES (OS-SPECIFIC)
# ============================================================================

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  count               = var.os_type == "Windows" ? 1 : 0
  name                = local.vm_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = local.admin_password
  tags                = local.common_tags

  # Windows-specific VM Configuration
  patch_mode                   = var.patch_mode
  hotpatching_enabled          = var.hotpatching_enabled
  timezone                     = var.timezone
  enable_automatic_updates     = var.enable_automatic_updates
  availability_set_id          = var.availability_set_id
  proximity_placement_group_id = var.proximity_placement_group_id
  zone                         = var.zone

  # Network Interface
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  # OS Disk Configuration
  os_disk {
    name                 = local.os_disk_name
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # VM Image Configuration
  source_image_reference {
    publisher = local.image_publisher
    offer     = local.image_offer
    sku       = local.image_sku
    version   = var.image_version
  }

  # Boot Diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []
    content {
      # Uses managed storage account (no storage_account_uri needed)
    }
  }

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.os_type == "Linux" ? 1 : 0
  name                = local.vm_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Linux-specific configuration
  disable_password_authentication = var.disable_password_authentication
  availability_set_id             = var.availability_set_id
  proximity_placement_group_id    = var.proximity_placement_group_id
  zone                            = var.zone

  # Network Interface
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  # OS Disk Configuration
  os_disk {
    name                 = local.os_disk_name
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # VM Image Configuration
  source_image_reference {
    publisher = local.image_publisher
    offer     = local.image_offer
    sku       = local.image_sku
    version   = var.image_version
  }

  # SSH Key Configuration (if provided)
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  # Password authentication (if not disabled and password provided)
  admin_password = !var.disable_password_authentication ? local.admin_password : null

  # Boot Diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []
    content {
      # Uses managed storage account (no storage_account_uri needed)
    }
  }

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }
}
