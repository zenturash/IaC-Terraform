# Architecture Information
output "architecture_mode" {
  description = "Current architecture deployment mode"
  value       = var.architecture_mode
}

# Single VNet Architecture Outputs (Backward Compatibility)
output "networking_resource_group_name" {
  description = "Name of the networking resource group (single-vnet mode)"
  value       = var.architecture_mode == "single-vnet" ? module.single_networking[0].networking_resource_group_name : null
}

output "virtual_network_name" {
  description = "Name of the virtual network (single-vnet mode)"
  value       = var.architecture_mode == "single-vnet" ? module.single_networking[0].vnet_name : null
}

output "virtual_network_id" {
  description = "ID of the virtual network (single-vnet mode)"
  value       = var.architecture_mode == "single-vnet" ? module.single_networking[0].vnet_id : null
}

output "subnet_names" {
  description = "List of all subnet names (single-vnet mode)"
  value       = var.architecture_mode == "single-vnet" ? module.single_networking[0].subnet_names : null
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs (single-vnet mode)"
  value       = var.architecture_mode == "single-vnet" ? module.single_networking[0].subnet_ids : null
}

output "subnets" {
  description = "Complete information about all subnets (single-vnet mode)"
  value       = var.architecture_mode == "single-vnet" ? module.single_networking[0].subnets : null
}

# Hub VNet Information (ALZ Hub-Spoke)
output "hub_vnet" {
  description = "Hub VNet information (hub-spoke mode)"
  value = var.architecture_mode == "hub-spoke" && var.hub_vnet.enabled ? {
    resource_group_name = module.hub_networking[0].networking_resource_group_name
    vnet_name          = module.hub_networking[0].vnet_name
    vnet_id            = module.hub_networking[0].vnet_id
    vnet_address_space = module.hub_networking[0].vnet_address_space
    subnet_names       = module.hub_networking[0].subnet_names
    subnet_ids         = module.hub_networking[0].subnet_ids
    subnets           = module.hub_networking[0].subnets
  } : null
}

# Spoke VNets Information (ALZ Hub-Spoke)
output "spoke_vnets" {
  description = "Spoke VNets information (hub-spoke mode)"
  value = var.architecture_mode == "hub-spoke" ? {
    for k, v in module.spoke_networking : k => {
      resource_group_name = v.networking_resource_group_name
      vnet_name          = v.vnet_name
      vnet_id            = v.vnet_id
      vnet_address_space = v.vnet_address_space
      subnet_names       = v.subnet_names
      subnet_ids         = v.subnet_ids
      subnets           = v.subnets
    }
  } : null
}

# VNet Peering Information (ALZ Hub-Spoke)
output "vnet_peering" {
  description = "VNet peering information (hub-spoke mode)"
  value = var.architecture_mode == "hub-spoke" && var.vnet_peering.enabled ? {
    hub_to_spoke_peering_ids   = module.vnet_peering[0].hub_to_spoke_peering_ids
    spoke_to_hub_peering_ids   = module.vnet_peering[0].spoke_to_hub_peering_ids
    hub_to_spoke_peering_names = module.vnet_peering[0].hub_to_spoke_peering_names
    spoke_to_hub_peering_names = module.vnet_peering[0].spoke_to_hub_peering_names
    peering_status            = module.vnet_peering[0].peering_status
    peering_summary           = module.vnet_peering[0].peering_summary
  } : null
}

# Virtual Machines Information
output "virtual_machines" {
  description = "Information about all created virtual machines"
  value = var.deploy_components.vms ? merge(
    {
      for vm_name, vm_module in module.vms_single : vm_name => {
        vm_id                = vm_module.vm_id
        vm_name              = vm_module.vm_name
        vm_size              = vm_module.vm_size
        resource_group_name  = vm_module.resource_group_name
        location             = vm_module.location
        private_ip_address   = vm_module.private_ip_address
        public_ip_address    = vm_module.public_ip_address
        rdp_connection_string = vm_module.rdp_connection_string
        admin_username       = vm_module.admin_username
        tags                 = vm_module.tags
      }
    },
    {
      for vm_name, vm_module in module.vms_spoke : vm_name => {
        vm_id                = vm_module.vm_id
        vm_name              = vm_module.vm_name
        vm_size              = vm_module.vm_size
        resource_group_name  = vm_module.resource_group_name
        location             = vm_module.location
        private_ip_address   = vm_module.private_ip_address
        public_ip_address    = vm_module.public_ip_address
        rdp_connection_string = vm_module.rdp_connection_string
        admin_username       = vm_module.admin_username
        tags                 = vm_module.tags
      }
    }
  ) : {}
}

# VM Resource Groups
output "vm_resource_groups" {
  description = "Map of VM names to their resource group names"
  value = var.deploy_components.vms ? merge(
    { for vm_name, vm_module in module.vms_single : vm_name => vm_module.resource_group_name },
    { for vm_name, vm_module in module.vms_spoke : vm_name => vm_module.resource_group_name }
  ) : {}
}

# VM IP Addresses
output "vm_private_ips" {
  description = "Map of VM names to their private IP addresses"
  value = var.deploy_components.vms ? merge(
    { for vm_name, vm_module in module.vms_single : vm_name => vm_module.private_ip_address },
    { for vm_name, vm_module in module.vms_spoke : vm_name => vm_module.private_ip_address }
  ) : {}
}

output "vm_public_ips" {
  description = "Map of VM names to their public IP addresses (if enabled)"
  value = var.deploy_components.vms ? merge(
    { for vm_name, vm_module in module.vms_single : vm_name => vm_module.public_ip_address },
    { for vm_name, vm_module in module.vms_spoke : vm_name => vm_module.public_ip_address }
  ) : {}
}

# RDP Connection Strings
output "rdp_connections" {
  description = "Map of VM names to their RDP connection strings"
  value = var.deploy_components.vms ? merge(
    { for vm_name, vm_module in module.vms_single : vm_name => vm_module.rdp_connection_string },
    { for vm_name, vm_module in module.vms_spoke : vm_name => vm_module.rdp_connection_string }
  ) : {}
}

# VPN Information (conditional)
output "vpn_gateway_info" {
  description = "VPN Gateway information (if VPN is enabled)"
  sensitive   = true
  value = var.deploy_components.vpn_gateway ? (
    var.architecture_mode == "single-vnet" && length(module.vpn_single) > 0 ? {
      vpn_gateway_name      = module.vpn_single[0].vpn_gateway_name
      vpn_gateway_public_ip = module.vpn_single[0].vpn_gateway_public_ip
      local_gateway_name    = module.vpn_single[0].local_network_gateway_name
      local_gateway_ip      = module.vpn_single[0].local_network_gateway_address
      connection_name       = module.vpn_single[0].vpn_connection_name
      connection_status     = module.vpn_single[0].vpn_connection_status
      vpn_type             = module.vpn_single[0].vpn_gateway_type
      sku                  = module.vpn_single[0].vpn_gateway_sku
      architecture         = var.architecture_mode
    } : var.architecture_mode == "hub-spoke" && length(module.vpn_hub) > 0 ? {
      vpn_gateway_name      = module.vpn_hub[0].vpn_gateway_name
      vpn_gateway_public_ip = module.vpn_hub[0].vpn_gateway_public_ip
      local_gateway_name    = module.vpn_hub[0].local_network_gateway_name
      local_gateway_ip      = module.vpn_hub[0].local_network_gateway_address
      connection_name       = module.vpn_hub[0].vpn_connection_name
      connection_status     = module.vpn_hub[0].vpn_connection_status
      vpn_type             = module.vpn_hub[0].vpn_gateway_type
      sku                  = module.vpn_hub[0].vpn_gateway_sku
      architecture         = var.architecture_mode
    } : null
  ) : null
}

output "vpn_summary" {
  description = "Complete VPN summary (if VPN is enabled)"
  sensitive   = true
  value = var.deploy_components.vpn_gateway ? (
    var.architecture_mode == "single-vnet" && length(module.vpn_single) > 0 ? module.vpn_single[0].vpn_summary :
    var.architecture_mode == "hub-spoke" && length(module.vpn_hub) > 0 ? module.vpn_hub[0].vpn_summary : null
  ) : null
}

# Datto RMM Policy Information
output "datto_rmm_policy" {
  description = "Datto RMM policy deployment information"
  sensitive   = true
  value = var.deploy_components.datto_policy ? {
    single_vnet_policy = var.architecture_mode == "single-vnet" && length(module.datto_rmm_policy_single) > 0 ? {
      policy_definition_id     = module.datto_rmm_policy_single[0].policy_definition_id
      policy_assignment_id     = module.datto_rmm_policy_single[0].policy_assignment_id
      managed_identity_id      = module.datto_rmm_policy_single[0].managed_identity_principal_id
      remediation_task_id      = module.datto_rmm_policy_single[0].remediation_task_id
      compliance_check_command = module.datto_rmm_policy_single[0].compliance_check_command
      policy_portal_url        = module.datto_rmm_policy_single[0].policy_portal_url
      configuration_summary    = module.datto_rmm_policy_single[0].configuration_summary
    } : null
    
    spoke_policies = var.architecture_mode == "hub-spoke" ? {
      for spoke_name, policy_module in module.datto_rmm_policy_spoke : spoke_name => {
        policy_definition_id     = policy_module.policy_definition_id
        policy_assignment_id     = policy_module.policy_assignment_id
        managed_identity_id      = policy_module.managed_identity_principal_id
        remediation_task_id      = policy_module.remediation_task_id
        compliance_check_command = policy_module.compliance_check_command
        policy_portal_url        = policy_module.policy_portal_url
        configuration_summary    = policy_module.configuration_summary
      }
    } : {}
    
    deployment_status = {
      enabled = true
      architecture_mode = var.architecture_mode
      total_policies_deployed = var.architecture_mode == "single-vnet" ? 1 : length(var.subscriptions.spoke)
      remediation_enabled = true
    }
  } : {
    single_vnet_policy = null
    spoke_policies = {}
    deployment_status = {
      enabled = false
      architecture_mode = var.architecture_mode
      total_policies_deployed = 0
      remediation_enabled = false
    }
  }
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of the deployment"
  sensitive   = true
  value = {
    architecture_mode = var.architecture_mode
    
    # Component deployment status
    components_deployed = {
      vpn_gateway  = var.deploy_components.vpn_gateway
      vms          = var.deploy_components.vms
      peering      = var.deploy_components.peering && var.architecture_mode == "hub-spoke"
      datto_policy = var.deploy_components.datto_policy
    }
    
    # Network information
    networks = var.architecture_mode == "hub-spoke" ? {
      hub_enabled = var.hub_vnet.enabled
      spoke_count = length([for k, v in var.spoke_vnets : k if v.enabled])
      peering_enabled = var.vnet_peering.enabled
    } : {
      single_vnet = true
      vnet_cidr = "10.0.0.0/20"
      subnet_count = 4  # Default subnets + gateway subnet if VPN enabled
    }
    
    # VM information
    virtual_machines = {
      total_vms = length(var.virtual_machines)
      vms_with_public_ip = length([
        for vm_name, vm_config in var.virtual_machines : vm_name
        if vm_config.enable_public_ip
      ])
      unique_resource_groups = length(distinct([
        for vm_name, vm_config in var.virtual_machines : vm_config.resource_group_name
      ]))
    }
    
    # VPN information
    vpn = {
      enabled = var.deploy_components.vpn_gateway
      gateway_sku = var.vpn_configuration.vpn_gateway_sku
      vpn_type = var.vpn_configuration.vpn_type
    }
  }
}

# Quick Connection Guide
output "connection_guide" {
  description = "Quick guide for connecting to resources"
  sensitive   = true
  value = {
    architecture = var.architecture_mode
    
    rdp_connections = var.deploy_components.vms ? concat(
      [
        for vm_name, vm_module in module.vms_single : {
          vm_name = vm_name
          connection_string = vm_module.rdp_connection_string
          has_public_ip = vm_module.public_ip_address != null
        }
      ],
      [
        for vm_name, vm_module in module.vms_spoke : {
          vm_name = vm_name
          connection_string = vm_module.rdp_connection_string
          has_public_ip = vm_module.public_ip_address != null
        }
      ]
    ) : []
    
    vpn_connection = var.deploy_components.vpn_gateway ? (
      var.architecture_mode == "single-vnet" && length(module.vpn_single) > 0 ? {
        gateway_public_ip = module.vpn_single[0].vpn_gateway_public_ip
        shared_key_configured = true
        connection_protocol = var.vpn_configuration.vpn_connection.connection_protocol
      } : var.architecture_mode == "hub-spoke" && length(module.vpn_hub) > 0 ? {
        gateway_public_ip = module.vpn_hub[0].vpn_gateway_public_ip
        shared_key_configured = true
        connection_protocol = var.vpn_configuration.vpn_connection.connection_protocol
      } : null
    ) : null
    
    network_access = var.architecture_mode == "hub-spoke" ? {
      hub_cidr = var.hub_vnet.enabled ? var.hub_vnet.cidr : null
      spoke_cidrs = {
        for k, v in var.spoke_vnets : k => v.cidr if v.enabled
      }
      peering_enabled = var.vnet_peering.enabled
      vnet_cidr = null
    } : {
      hub_cidr = null
      spoke_cidrs = {}
      peering_enabled = false
      vnet_cidr = length(module.single_networking) > 0 ? module.single_networking[0].vnet_address_space[0] : null
    }
  }
}
