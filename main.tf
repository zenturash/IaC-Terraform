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

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Create networking resources
module "networking" {
  source = "./modules/azure-networking"

  vnet_name           = "vnet-multi-vm"
  resource_group_name = "rg-networking-multi-vm"
  location            = var.location
  vnet_cidr           = var.vnet_cidr
  
  # Use configurable subnet names - CIDRs calculated automatically
  subnet_names = var.subnet_names
  create_gateway_subnet = var.create_gateway_subnet
  
  tags = {
    creation_date   = formatdate("YYYY-MM-DD", timestamp())
    creation_method = "OpenTofu"
    environment     = "POC"
    project         = "Azure Multi-VM POC"
    tier           = "networking"
  }
}

# Create multiple VMs using for_each
module "vms" {
  source = "./modules/azure-vm"
  for_each = var.virtual_machines

  # Required variables
  vm_name        = each.key
  admin_username = each.value.admin_username != null ? each.value.admin_username : var.admin_username
  admin_password = each.value.admin_password != null ? each.value.admin_password : var.admin_password
  subnet_id      = module.networking.subnet_ids[each.value.subnet_name]

  # Optional variables
  vm_size          = each.value.vm_size
  location         = var.location
  enable_public_ip = each.value.enable_public_ip

  # Network configuration - separate RG for each VM
  resource_group_name = each.value.resource_group_name

  # Storage configuration
  os_disk_type = each.value.os_disk_type
  
  # NSG configuration
  nsg_rules = each.value.nsg_rules
}

# Create VPN Gateway and connection (conditional)
module "vpn" {
  count  = var.enable_vpn ? 1 : 0
  source = "./modules/azure-vpn"

  # Required variables
  vpn_gateway_name    = var.vpn_configuration.vpn_gateway_name
  resource_group_name = module.networking.networking_resource_group_name
  location            = var.location
  gateway_subnet_id   = module.networking.subnet_ids["GatewaySubnet"]

  # VPN Gateway configuration
  vpn_gateway_sku        = var.vpn_configuration.vpn_gateway_sku
  vpn_type              = var.vpn_configuration.vpn_type
  enable_bgp            = var.vpn_configuration.enable_bgp

  # Local Network Gateway configuration
  local_network_gateway = var.vpn_configuration.local_network_gateway

  # VPN Connection configuration
  vpn_connection = var.vpn_configuration.vpn_connection

  tags = {
    creation_date   = formatdate("YYYY-MM-DD", timestamp())
    creation_method = "OpenTofu"
    environment     = "POC"
    project         = "Azure Multi-VM POC"
    tier           = "vpn"
  }

  # Ensure networking is created first
  depends_on = [module.networking]
}
