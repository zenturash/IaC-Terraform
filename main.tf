# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Microsoft Azure Provider (Default)
provider "azurerm" {
  features {}
}

# Configure Azure Provider for Hub Subscription (if different)
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.subscriptions.hub
  features {}
}

# Configure Azure Provider for Spoke Subscription (default)
provider "azurerm" {
  alias           = "spoke"
  subscription_id = length(var.subscriptions.spoke) > 0 ? values(var.subscriptions.spoke)[0] : null
  features {}
}

# Data source for current client configuration (needed for subscription ID)
data "azurerm_client_config" "current" {}


# Local values for common tags and configuration
locals {
  # Merge global tags with automatic tags
  common_tags = merge(var.global_tags, {
    creation_date = formatdate("YYYY-MM-DD", timestamp())
  })
  
  # Determine which VNet to use for VMs based on architecture mode
  vm_vnet_subnet_ids = var.architecture_mode == "hub-spoke" ? (
    length(module.spoke_networking) > 0 ? values(module.spoke_networking)[0].subnet_ids : {}
  ) : length(module.single_networking) > 0 ? module.single_networking[0].subnet_ids : {}
  
  # Create a map of all subnet IDs across hub and spokes for VM deployment
  all_subnet_ids = var.architecture_mode == "hub-spoke" ? merge(
    # Hub subnets
    length(module.hub_networking) > 0 ? module.hub_networking[0].subnet_ids : {},
    # All spoke subnets
    flatten([
      for spoke_name, spoke_module in module.spoke_networking : [
        for subnet_name, subnet_id in spoke_module.subnet_ids : {
          "${spoke_name}/${subnet_name}" = subnet_id
          "${subnet_name}" = subnet_id  # Also allow direct subnet name lookup for backward compatibility
        }
      ]
    ])...
  ) : local.vm_vnet_subnet_ids
  
  # Determine which VNet to use for VPN based on architecture mode
  vpn_vnet_info = var.architecture_mode == "hub-spoke" ? {
    resource_group_name = module.hub_networking[0].networking_resource_group_name
    gateway_subnet_id   = module.hub_networking[0].subnet_ids["GatewaySubnet"]
  } : {
    resource_group_name = module.single_networking[0].networking_resource_group_name
    gateway_subnet_id   = module.single_networking[0].subnet_ids["GatewaySubnet"]
  }
}

# STEP 1: Deploy Networking Infrastructure

# Single VNet Architecture (Original/Backward Compatibility)
module "single_networking" {
  count  = var.architecture_mode == "single-vnet" ? 1 : 0
  source = "./modules/azure-networking"

  vnet_name           = "vnet-single-legacy"
  resource_group_name = "rg-networking-single"
  location            = var.location
  vnet_cidr           = "10.0.0.0/20"
  
  # Use default subnet names for single-vnet mode
  subnet_names = ["subnet-default", "subnet-app", "subnet-mgmt"]
  create_gateway_subnet = var.deploy_components.vpn_gateway
  
  tags = merge(local.common_tags, {
    tier = "networking-single"
  })
}

# Hub VNet (ALZ Hub-Spoke Architecture)
module "hub_networking" {
  count  = var.architecture_mode == "hub-spoke" && var.hub_vnet.enabled ? 1 : 0
  source = "./modules/azure-networking"

  providers = {
    azurerm = azurerm.hub
  }

  vnet_name           = var.hub_vnet.name
  resource_group_name = var.hub_vnet.resource_group_name
  location            = var.hub_vnet.location != null ? var.hub_vnet.location : var.location
  vnet_cidr           = var.hub_vnet.cidr
  
  subnet_names = [for subnet in var.hub_vnet.subnets : subnet if subnet != "GatewaySubnet"]
  create_gateway_subnet = contains(var.hub_vnet.subnets, "GatewaySubnet") || var.deploy_components.vpn_gateway
  
  tags = merge(local.common_tags, {
    tier = "networking-hub"
    role = "connectivity"
  })
}

# Spoke VNets (ALZ Hub-Spoke Architecture)
module "spoke_networking" {
  for_each = var.architecture_mode == "hub-spoke" ? {
    for k, v in var.spoke_vnets : k => v if v.enabled
  } : {}
  
  source = "./modules/azure-networking"

  providers = {
    azurerm = azurerm.spoke
  }

  vnet_name           = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location != null ? each.value.location : var.location
  vnet_cidr           = each.value.cidr
  
  subnet_names = each.value.subnets
  create_gateway_subnet = false  # Spokes don't need gateway subnets
  
  tags = merge(local.common_tags, {
    tier = "networking-spoke"
    role = "workload"
    spoke_name = each.key
    subscription_id = lookup(var.subscriptions.spoke, each.value.spoke_name != null ? each.value.spoke_name : each.key, null)
  })
}

# VNet Peering (ALZ Hub-Spoke Architecture)
module "vnet_peering" {
  count  = var.architecture_mode == "hub-spoke" && var.vnet_peering.enabled && var.hub_vnet.enabled ? 1 : 0
  source = "./modules/azure-vnet-peering"

  providers = {
    azurerm.hub   = azurerm.hub
    azurerm.spoke = azurerm.spoke
  }

  # Hub VNet information
  hub_vnet_id               = module.hub_networking[0].vnet_id
  hub_vnet_name             = module.hub_networking[0].vnet_name
  hub_resource_group_name   = module.hub_networking[0].networking_resource_group_name

  # Spoke VNets to peer
  peering_connections = {
    for k, v in var.spoke_vnets : k => {
      spoke_vnet_id               = module.spoke_networking[k].vnet_id
      spoke_vnet_name             = module.spoke_networking[k].vnet_name
      spoke_resource_group_name   = module.spoke_networking[k].networking_resource_group_name
    } if v.enabled && v.peer_to_hub
  }

  # Peering configuration
  peering_config = {
    allow_virtual_network_access = var.vnet_peering.allow_virtual_network_access
    allow_forwarded_traffic      = var.vnet_peering.allow_forwarded_traffic
    allow_gateway_transit        = var.vnet_peering.allow_gateway_transit
    use_remote_gateways         = var.vnet_peering.use_remote_gateways
  }

  tags = merge(local.common_tags, {
    tier = "networking-peering"
  })

  depends_on = [module.hub_networking, module.spoke_networking]
}

# Virtual Machines (Single VNet mode)
module "vms_single" {
  for_each = var.architecture_mode == "single-vnet" && var.deploy_components.vms ? var.virtual_machines : {}
  source = "./modules/azure-vm"

  # Required variables (generalized module)
  subnet_id           = local.vm_vnet_subnet_ids[each.value.subnet_name]
  admin_username      = each.value.admin_username != null ? each.value.admin_username : var.admin_username
  resource_group_name = each.value.resource_group_name

  # Optional variables with smart defaults
  vm_name             = each.key  # Use the key as VM name
  admin_password      = each.value.admin_password != null ? each.value.admin_password : var.admin_password
  vm_size             = each.value.vm_size
  location            = var.location
  enable_public_ip    = each.value.enable_public_ip
  os_disk_type        = each.value.os_disk_type
  
  # NSG configuration (generalized approach)
  create_nsg = length(each.value.nsg_rules) > 0
  nsg_rules  = each.value.nsg_rules

  # Tags configuration
  tags = merge(local.common_tags, {
    tier = "vm"
    architecture = var.architecture_mode
  })

  # VMs deployed after networking
  depends_on = [
    module.single_networking
  ]
}

# Virtual Machines (Hub-Spoke mode - deployed across multiple spokes)
module "vms_spoke" {
  for_each = var.architecture_mode == "hub-spoke" && var.deploy_components.vms ? var.virtual_machines : {}
  source = "./modules/azure-vm"

  providers = {
    azurerm = azurerm.spoke
  }

  # Required variables (generalized module)
  subnet_id = each.value.spoke_name != null ? (
    # If spoke_name is specified, look for subnet in that specific spoke
    contains(keys(module.spoke_networking), each.value.spoke_name) ? 
      module.spoke_networking[each.value.spoke_name].subnet_ids[each.value.subnet_name] :
      # Fallback to hub if spoke not found and subnet exists in hub
      (length(module.hub_networking) > 0 && contains(keys(module.hub_networking[0].subnet_ids), each.value.subnet_name) ?
        module.hub_networking[0].subnet_ids[each.value.subnet_name] :
        null
      )
  ) : (
    # If no spoke_name specified, use backward compatibility logic
    length(module.spoke_networking) > 0 ? values(module.spoke_networking)[0].subnet_ids[each.value.subnet_name] :
    (length(module.hub_networking) > 0 ? module.hub_networking[0].subnet_ids[each.value.subnet_name] : null)
  )
  admin_username      = each.value.admin_username != null ? each.value.admin_username : var.admin_username
  resource_group_name = each.value.resource_group_name

  # Optional variables with smart defaults
  vm_name             = each.key  # Use the key as VM name
  admin_password      = each.value.admin_password != null ? each.value.admin_password : var.admin_password
  vm_size             = each.value.vm_size
  location            = var.location
  enable_public_ip    = each.value.enable_public_ip
  os_disk_type        = each.value.os_disk_type
  
  # NSG configuration (generalized approach)
  create_nsg = length(each.value.nsg_rules) > 0
  nsg_rules  = each.value.nsg_rules

  # Tags configuration
  tags = merge(local.common_tags, {
    tier = "vm"
    architecture = var.architecture_mode
    spoke_name = each.value.spoke_name
  })

  # VMs deployed after networking
  depends_on = [
    module.spoke_networking, 
    module.hub_networking
  ]
}

# VPN Gateway and connection (Single VNet mode)
module "vpn_single" {
  count  = var.architecture_mode == "single-vnet" && var.deploy_components.vpn_gateway ? 1 : 0
  source = "./modules/azure-vpn"

  # Required variables (generalized module)
  resource_group_name = local.vpn_vnet_info.resource_group_name
  location            = var.location
  gateway_subnet_id   = local.vpn_vnet_info.gateway_subnet_id

  # Optional VPN Gateway configuration
  vpn_gateway_name = var.vpn_configuration.vpn_gateway_name
  vpn_gateway_sku  = var.vpn_configuration.vpn_gateway_sku
  vpn_type         = var.vpn_configuration.vpn_type
  enable_bgp       = var.vpn_configuration.enable_bgp

  # Optional Local Network Gateway and Connection configuration
  local_network_gateway = var.vpn_configuration.local_network_gateway
  vpn_connection        = var.vpn_configuration.vpn_connection

  tags = merge(local.common_tags, {
    tier = "vpn"
    architecture = var.architecture_mode
  })

  depends_on = [module.single_networking]
}

# VPN Gateway and connection (Hub-Spoke mode - deployed in hub subscription)
module "vpn_hub" {
  count  = var.architecture_mode == "hub-spoke" && var.deploy_components.vpn_gateway ? 1 : 0
  source = "./modules/azure-vpn"

  providers = {
    azurerm = azurerm.hub
  }

  # Required variables (generalized module)
  resource_group_name = local.vpn_vnet_info.resource_group_name
  location            = var.location
  gateway_subnet_id   = local.vpn_vnet_info.gateway_subnet_id

  # Optional VPN Gateway configuration
  vpn_gateway_name = var.vpn_configuration.vpn_gateway_name
  vpn_gateway_sku  = var.vpn_configuration.vpn_gateway_sku
  vpn_type         = var.vpn_configuration.vpn_type
  enable_bgp       = var.vpn_configuration.enable_bgp

  # Optional Local Network Gateway and Connection configuration
  local_network_gateway = var.vpn_configuration.local_network_gateway
  vpn_connection        = var.vpn_configuration.vpn_connection

  tags = merge(local.common_tags, {
    tier = "vpn"
    architecture = var.architecture_mode
  })

  depends_on = [module.hub_networking]
}

# ============================================================================
# BACKUP SERVICES
# ============================================================================

# Backup Services (Single VNet mode)
module "backup_services_single" {
  count  = var.architecture_mode == "single-vnet" && var.deploy_components.backup_services ? 1 : 0
  source = "./modules/azure-backup"

  # Required variables (generalized module)
  resource_group_name = var.backup_configuration.resource_group_name

  # Optional configuration with smart defaults
  location = var.location
  
  # Backup policies configuration (security-first: opt-in)
  create_backup_policies = var.backup_configuration.policies
  
  # VM backup configuration
  vm_backup_time           = var.backup_configuration.vm_backup_time
  vm_backup_retention_days = var.backup_configuration.vm_backup_retention_days
  vm_backup_timezone       = var.backup_configuration.vm_backup_timezone
  
  # Files backup configuration
  files_backup_time           = var.backup_configuration.files_backup_time
  files_backup_retention_days = var.backup_configuration.files_backup_retention_days
  
  # Blob backup configuration
  blob_backup_retention_days = var.backup_configuration.blob_backup_retention_days
  
  # SQL backup configuration
  sql_full_backup_time           = var.backup_configuration.sql_full_backup_time
  sql_full_backup_retention_days = var.backup_configuration.sql_full_backup_retention_days
  sql_log_backup_frequency_minutes = var.backup_configuration.sql_log_backup_frequency_minutes
  sql_log_backup_retention_days  = var.backup_configuration.sql_log_backup_retention_days
  
  # Alert configuration
  enable_backup_alerts = var.backup_configuration.enable_backup_alerts
  alert_send_to_owners = var.backup_configuration.alert_send_to_owners
  alert_custom_email_addresses = var.backup_configuration.alert_custom_email_addresses
  
  # Custom backup policies (for advanced scenarios)
  custom_backup_policies = var.backup_configuration.custom_backup_policies
  
  # Tags configuration
  tags = merge(local.common_tags, {
    tier = "backup"
    architecture = var.architecture_mode
  })

  # Backup services deployed after networking
  depends_on = [
    module.single_networking
  ]
}

# Backup Services (Hub-Spoke mode - deployed in hub subscription)
module "backup_services_hub" {
  count  = var.architecture_mode == "hub-spoke" && var.deploy_components.backup_services ? 1 : 0
  source = "./modules/azure-backup"

  providers = {
    azurerm = azurerm.hub
  }

  # Required variables (generalized module)
  resource_group_name = var.backup_configuration.resource_group_name

  # Optional configuration with smart defaults
  location = var.location
  
  # Backup policies configuration (security-first: opt-in)
  create_backup_policies = var.backup_configuration.policies
  
  # VM backup configuration
  vm_backup_time           = var.backup_configuration.vm_backup_time
  vm_backup_retention_days = var.backup_configuration.vm_backup_retention_days
  vm_backup_timezone       = var.backup_configuration.vm_backup_timezone
  
  # Files backup configuration
  files_backup_time           = var.backup_configuration.files_backup_time
  files_backup_retention_days = var.backup_configuration.files_backup_retention_days
  
  # Blob backup configuration
  blob_backup_retention_days = var.backup_configuration.blob_backup_retention_days
  
  # SQL backup configuration
  sql_full_backup_time           = var.backup_configuration.sql_full_backup_time
  sql_full_backup_retention_days = var.backup_configuration.sql_full_backup_retention_days
  sql_log_backup_frequency_minutes = var.backup_configuration.sql_log_backup_frequency_minutes
  sql_log_backup_retention_days  = var.backup_configuration.sql_log_backup_retention_days
  
  # Alert configuration
  enable_backup_alerts = var.backup_configuration.enable_backup_alerts
  alert_send_to_owners = var.backup_configuration.alert_send_to_owners
  alert_custom_email_addresses = var.backup_configuration.alert_custom_email_addresses
  
  # Custom backup policies (for advanced scenarios)
  custom_backup_policies = var.backup_configuration.custom_backup_policies
  
  # Tags configuration
  tags = merge(local.common_tags, {
    tier = "backup"
    architecture = var.architecture_mode
  })

  # Backup services deployed after networking
  depends_on = [
    module.hub_networking
  ]
}

# ============================================================================
# SQL SERVER VIRTUAL MACHINES
# ============================================================================

# SQL Server VMs (Single VNet mode)
module "sql_vms_single" {
  for_each = var.architecture_mode == "single-vnet" ? var.sql_server_vms : {}
  source = "./modules/azure-sql-vm"

  # Required variables
  subnet_id           = local.vm_vnet_subnet_ids[each.value.subnet_name]
  resource_group_name = each.value.resource_group_name
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  # Optional variables with defaults
  vm_name             = each.key  # Use the key as VM name
  vm_size             = each.value.vm_size
  sql_edition         = each.value.sql_edition
  location            = var.location
  enable_public_ip    = each.value.enable_public_ip
  
  # Storage configuration
  data_disk_config = each.value.data_disk_config
  log_disk_config  = each.value.log_disk_config
  
  # Security configuration
  create_nsg    = each.value.create_nsg
  sql_nsg_rules = each.value.sql_nsg_rules
  
  # Tags
  tags = merge(local.common_tags, {
    tier = "sql-server"
    architecture = var.architecture_mode
  }, each.value.tags)

  # SQL Server VMs deployed after networking
  depends_on = [
    module.single_networking
  ]
}

# SQL Server VMs (Hub-Spoke mode - deployed across multiple spokes)
module "sql_vms_spoke" {
  for_each = var.architecture_mode == "hub-spoke" ? var.sql_server_vms : {}
  source = "./modules/azure-sql-vm"

  providers = {
    azurerm = azurerm.spoke
  }

  # Required variables with subnet resolution logic
  subnet_id = each.value.spoke_name != null ? (
    # If spoke_name is specified, look for subnet in that specific spoke
    contains(keys(module.spoke_networking), each.value.spoke_name) ? 
      module.spoke_networking[each.value.spoke_name].subnet_ids[each.value.subnet_name] :
      # Fallback to hub if spoke not found and subnet exists in hub
      (length(module.hub_networking) > 0 && contains(keys(module.hub_networking[0].subnet_ids), each.value.subnet_name) ?
        module.hub_networking[0].subnet_ids[each.value.subnet_name] :
        null
      )
  ) : (
    # If no spoke_name specified, use backward compatibility logic
    length(module.spoke_networking) > 0 ? values(module.spoke_networking)[0].subnet_ids[each.value.subnet_name] :
    (length(module.hub_networking) > 0 ? module.hub_networking[0].subnet_ids[each.value.subnet_name] : null)
  )
  resource_group_name = each.value.resource_group_name
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  # Optional variables with defaults
  vm_name             = each.key  # Use the key as VM name
  vm_size             = each.value.vm_size
  sql_edition         = each.value.sql_edition
  location            = var.location
  enable_public_ip    = each.value.enable_public_ip
  
  # Storage configuration
  data_disk_config = each.value.data_disk_config
  log_disk_config  = each.value.log_disk_config
  
  # Security configuration
  create_nsg    = each.value.create_nsg
  sql_nsg_rules = each.value.sql_nsg_rules
  
  # Tags
  tags = merge(local.common_tags, {
    tier = "sql-server"
    architecture = var.architecture_mode
    spoke_name = each.value.spoke_name
  }, each.value.tags)

  # SQL Server VMs deployed after networking
  depends_on = [
    module.spoke_networking, 
    module.hub_networking
  ]
}
