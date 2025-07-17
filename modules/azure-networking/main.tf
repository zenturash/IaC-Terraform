# ============================================================================
# LOCAL VALUES FOR CONSISTENT CONFIGURATION
# ============================================================================

locals {
  # Comprehensive tagging
  base_tags = var.enable_auto_tagging ? {
    vnet_name         = var.vnet_name
    vnet_cidr         = var.vnet_cidr
    subnet_count      = length(var.subnet_names)
    gateway_subnet    = var.create_gateway_subnet
    creation_date     = formatdate("YYYY-MM-DD", timestamp())
    creation_time     = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method   = "OpenTofu"
    location          = var.location
    dns_servers       = length(var.dns_servers) > 0 ? join(",", var.dns_servers) : "Azure Default"
    ddos_protection   = var.ddos_protection_plan_id != null
    vm_protection     = var.enable_vm_protection
    encryption        = var.encryption
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
  
  # Calculate subnet CIDRs automatically using cidrsubnets function
  regular_subnet_cidrs = cidrsubnets(var.vnet_cidr, [for i in range(length(var.subnet_names)) : var.subnet_newbits]...)
  
  # Regular subnets get the first CIDRs
  regular_subnets = {
    for i, name in var.subnet_names : name => {
      cidr = local.regular_subnet_cidrs[i]
    }
  }
  
  # Gateway subnet gets the LAST possible subnet in the entire VNet address space
  # For 10.0.0.0/20, this would be 10.0.15.0/24 (with newbits=4)
  gateway_subnet = var.create_gateway_subnet ? {
    "GatewaySubnet" = {
      cidr = cidrsubnet(var.vnet_cidr, var.gateway_subnet_newbits, pow(2, var.gateway_subnet_newbits) - 1)
    }
  } : {}
  
  # Combine all subnets
  subnets = merge(local.regular_subnets, local.gateway_subnet)
}

# ============================================================================
# RESOURCE GROUP FOR NETWORKING
# ============================================================================

resource "azurerm_resource_group" "networking" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ============================================================================
# VIRTUAL NETWORK
# ============================================================================

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = local.common_tags

  # DNS servers configuration
  dns_servers = length(var.dns_servers) > 0 ? var.dns_servers : null

  # DDoS protection plan
  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  # Flow timeout configuration
  flow_timeout_in_minutes = var.flow_timeout_in_minutes

  # BGP community
  bgp_community = var.bgp_community

  # Encryption (if supported by provider version)
  dynamic "encryption" {
    for_each = var.encryption != "AllowUnencrypted" ? [1] : []
    content {
      enforcement = var.encryption
    }
  }
}

# ============================================================================
# SUBNETS WITH ADVANCED CONFIGURATION
# ============================================================================

resource "azurerm_subnet" "subnets" {
  for_each = local.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr]

  # Service endpoints
  service_endpoints = lookup(var.subnet_service_endpoints, each.key, [])

  # Service endpoint policies
  service_endpoint_policy_ids = lookup(var.subnet_service_endpoint_policies, each.key, [])

  # Private link service network policies (azurerm v3.x compatible)
  private_link_service_network_policies_enabled = lookup(var.subnet_private_link_service_network_policies_enabled, each.key, true)

  # Subnet delegation
  dynamic "delegation" {
    for_each = lookup(var.subnet_delegations, each.key, null) != null ? [var.subnet_delegations[each.key]] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# ============================================================================
# NETWORK SECURITY GROUPS (CREATED BY MODULE)
# ============================================================================

resource "azurerm_network_security_group" "subnet_nsgs" {
  for_each = var.create_subnet_nsgs

  name                = "${var.nsg_name_prefix}-${each.key}"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = merge(local.common_tags, lookup(var.subnet_tags, each.key, {}))
}

# NSG Rules for created NSGs
resource "azurerm_network_security_rule" "subnet_nsg_rules" {
  for_each = {
    for rule_key, rule in flatten([
      for subnet_name, rules in var.subnet_nsg_rules : [
        for rule in rules : {
          key         = "${subnet_name}-${rule.name}"
          subnet_name = subnet_name
          rule        = rule
        }
      ]
    ]) : rule_key => rule if lookup(var.create_subnet_nsgs, rule.subnet_name, false)
  }

  name                        = each.value.rule.name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = each.value.rule.source_port_range
  destination_port_range      = each.value.rule.destination_port_range
  source_address_prefix       = each.value.rule.source_address_prefix
  destination_address_prefix  = each.value.rule.destination_address_prefix
  resource_group_name         = azurerm_resource_group.networking.name
  network_security_group_name = azurerm_network_security_group.subnet_nsgs[each.value.subnet_name].name
}

# ============================================================================
# NETWORK SECURITY GROUP ASSOCIATIONS
# ============================================================================

# Associate created NSGs with their subnets
resource "azurerm_subnet_network_security_group_association" "created_nsg_associations" {
  for_each = var.create_subnet_nsgs

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet_nsgs[each.key].id
}

# Associate external NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "external_nsg_associations" {
  for_each = var.subnet_nsg_associations

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = each.value
}

# ============================================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================================

resource "azurerm_subnet_route_table_association" "route_table_associations" {
  for_each = var.subnet_route_table_associations

  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = each.value
}
