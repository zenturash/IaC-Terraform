# ============================================================================
# LOCAL VALUES FOR CONSISTENT NAMING AND CONFIGURATION
# ============================================================================

locals {
  # Determine VM name (auto-generate if not provided)
  vm_name = var.vm_name != null ? var.vm_name : "sqlvm-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  
  # Resource names with prefixes
  public_ip_name = "${var.public_ip_name_prefix}-${local.vm_name}"
  nsg_name       = "${var.nsg_name_prefix}-${local.vm_name}"
  nic_name       = "${var.nic_name_prefix}-${local.vm_name}"
  os_disk_name   = var.os_disk_name != null ? var.os_disk_name : "osdisk-${local.vm_name}"
  data_disk_name = "${var.data_disk_name_prefix}-${local.vm_name}"
  log_disk_name  = "${var.log_disk_name_prefix}-${local.vm_name}"
  
  # Resource group name
  resource_group_name = var.resource_group_name
  
  # SQL Server image configuration
  image_publisher = var.sql_image_defaults.publisher
  image_offer     = var.sql_image_defaults.offer
  image_sku       = var.sql_image_defaults.sku
  
  # Connection IP for outputs
  connection_ip = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : azurerm_network_interface.main.private_ip_address
  
  # Comprehensive tagging for SQL Server VMs
  base_tags = var.enable_auto_tagging ? {
    vm_name                = local.vm_name
    vm_size                = var.vm_size
    sql_server_version     = "SQL Server 2022"
    sql_server_edition     = var.sql_edition
    sql_image              = "${local.image_publisher}-${local.image_offer}-${local.image_sku}"
    os_disk_type           = var.os_disk_type
    data_disk_size_gb      = var.data_disk_config.size_gb
    data_disk_type         = var.data_disk_config.storage_account_type
    log_disk_size_gb       = var.log_disk_config.size_gb
    log_disk_type          = var.log_disk_config.storage_account_type
    sql_port               = var.sql_port
    sql_connectivity_type  = var.sql_connectivity_type
    sql_authentication     = var.sql_authentication_type
    creation_date          = formatdate("YYYY-MM-DD", timestamp())
    creation_time          = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method        = "OpenTofu"
    admin_username         = var.admin_username
    location               = var.location
    public_ip_enabled      = var.enable_public_ip
    auto_generated         = var.vm_name == null
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
  
  # NSG rules are only the ones explicitly defined by the user
  all_nsg_rules = var.sql_nsg_rules
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
# NETWORK SECURITY GROUP (CONDITIONAL - SECURITY-FIRST)
# ============================================================================

resource "azurerm_network_security_group" "main" {
  count               = var.create_nsg ? 1 : 0
  name                = local.nsg_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  tags                = local.common_tags
}

# NSG Rules (only explicit rules - no automatic SQL Server rules)
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

# Associate NSG with Network Interface (conditional)
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.create_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

# ============================================================================
# MANAGED DISKS FOR SQL SERVER (DATA AND LOG)
# ============================================================================

# Data disk for SQL Server databases
resource "azurerm_managed_disk" "data_disk" {
  name                 = local.data_disk_name
  location             = local.resource_group.location
  resource_group_name  = local.resource_group.name
  storage_account_type = var.data_disk_config.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_config.size_gb
  zone                 = var.zone
  tags                 = merge(local.common_tags, {
    disk_purpose = "SQL Server Data Files"
    disk_type    = "Data"
  })
}

# Log disk for SQL Server transaction logs
resource "azurerm_managed_disk" "log_disk" {
  name                 = local.log_disk_name
  location             = local.resource_group.location
  resource_group_name  = local.resource_group.name
  storage_account_type = var.log_disk_config.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.log_disk_config.size_gb
  zone                 = var.zone
  tags                 = merge(local.common_tags, {
    disk_purpose = "SQL Server Log Files"
    disk_type    = "Log"
  })
}

# ============================================================================
# SQL SERVER VIRTUAL MACHINE
# ============================================================================

resource "azurerm_windows_virtual_machine" "main" {
  name                = local.vm_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = local.common_tags

  # SQL Server VM Configuration
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
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # SQL Server Image Configuration
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

# ============================================================================
# DISK ATTACHMENTS FOR SQL SERVER
# ============================================================================

# Attach data disk to SQL Server VM
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  lun                = var.data_disk_config.lun
  caching            = var.data_disk_config.caching
}

# Attach log disk to SQL Server VM
resource "azurerm_virtual_machine_data_disk_attachment" "log_disk" {
  managed_disk_id    = azurerm_managed_disk.log_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  lun                = var.log_disk_config.lun
  caching            = var.log_disk_config.caching
}

# ============================================================================
# SQL SERVER IAAS AGENT EXTENSION
# ============================================================================

# SQL Server IaaS Agent Extension for basic SQL Server management
resource "azurerm_mssql_virtual_machine" "main" {
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  sql_license_type   = var.sql_license_type
  
  # SQL Server connectivity configuration
  sql_connectivity_update_password = var.admin_password
  sql_connectivity_update_username = var.admin_username  # Same as VM admin (as requested)
  sql_connectivity_type            = var.sql_connectivity_type
  sql_connectivity_port            = var.sql_port
  
  # Auto backup configuration (optional)
  dynamic "auto_backup" {
    for_each = var.enable_auto_backup ? [1] : []
    content {
      retention_period_in_days = var.auto_backup_retention_days
      storage_blob_endpoint    = var.backup_storage_endpoint
      storage_account_access_key = var.backup_storage_access_key
    }
  }
  
  # Auto patching configuration (optional)
  dynamic "auto_patching" {
    for_each = var.enable_auto_patching ? [1] : []
    content {
      day_of_week                            = var.auto_patching_day_of_week
      maintenance_window_starting_hour       = var.auto_patching_start_hour
      maintenance_window_duration_in_minutes = var.auto_patching_window_duration
    }
  }
  
  tags = local.common_tags
  
  # Ensure the extension is installed after VM and disks are ready
  depends_on = [
    azurerm_windows_virtual_machine.main,
    azurerm_virtual_machine_data_disk_attachment.data_disk,
    azurerm_virtual_machine_data_disk_attachment.log_disk
  ]
}
