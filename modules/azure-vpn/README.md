# Azure VPN Module

This module creates Azure VPN Gateway infrastructure for site-to-site VPN connectivity, including VPN Gateway, Local Network Gateway, and VPN Connection.

## Features

- **VPN Gateway**: Route-based or policy-based VPN gateways
- **Multiple SKUs**: Support for Basic to VpnGw5AZ gateway SKUs
- **BGP Support**: Optional Border Gateway Protocol configuration
- **IPSec Policies**: Custom IPSec/IKE policies for enhanced security
- **Public IP Management**: Automatic public IP creation with appropriate SKU
- **Connection Management**: Complete site-to-site VPN connection setup
- **Timeout Handling**: Extended timeouts for gateway creation (up to 60 minutes)

## Usage

### Basic VPN Gateway

```hcl
module "vpn" {
  source = "./modules/azure-vpn"

  vpn_gateway_name    = "vpn-gateway-main"
  resource_group_name = "rg-connectivity"
  location            = "West Europe"
  gateway_subnet_id   = "/subscriptions/.../subnets/GatewaySubnet"

  local_network_gateway = {
    name            = "local-gateway-office"
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16"]
  }

  vpn_connection = {
    name       = "vpn-connection-office"
    shared_key = "YourSecureSharedKey123!"
  }

  tags = {
    environment = "production"
    tier        = "connectivity"
  }
}
```

### Advanced VPN with BGP

```hcl
module "vpn_bgp" {
  source = "./modules/azure-vpn"

  vpn_gateway_name = "vpn-gateway-bgp"
  resource_group_name = "rg-connectivity"
  location = "West Europe"
  gateway_subnet_id = "/subscriptions/.../subnets/GatewaySubnet"

  vpn_gateway_sku = "VpnGw1"
  vpn_type = "RouteBased"
  enable_bgp = true

  bgp_settings = {
    asn         = 65515
    peer_weight = 0
  }

  local_network_gateway = {
    name            = "local-gateway-bgp"
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16"]
  }

  vpn_connection = {
    name                = "vpn-connection-bgp"
    shared_key          = "YourSecureSharedKey123!"
    connection_protocol = "IKEv2"
  }

  tags = {
    environment = "production"
    tier        = "connectivity"
    bgp_enabled = "true"
  }
}
```

### High-Performance VPN

```hcl
module "vpn_high_perf" {
  source = "./modules/azure-vpn"

  vpn_gateway_name = "vpn-gateway-perf"
  resource_group_name = "rg-connectivity"
  location = "West Europe"
  gateway_subnet_id = "/subscriptions/.../subnets/GatewaySubnet"

  vpn_gateway_sku        = "VpnGw3"
  vpn_gateway_generation = "Generation2"
  vpn_type              = "RouteBased"

  local_network_gateway = {
    name            = "local-gateway-perf"
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16", "10.10.0.0/16"]
  }

  vpn_connection = {
    name                = "vpn-connection-perf"
    shared_key          = "YourSecureSharedKey123!"
    connection_protocol = "IKEv2"
    ipsec_policy = {
      dh_group         = "DHGroup24"
      ike_encryption   = "AES256"
      ike_integrity    = "SHA384"
      ipsec_encryption = "AES256"
      ipsec_integrity  = "SHA256"
      pfs_group        = "PFS24"
      sa_lifetime      = 7200
    }
  }

  tags = {
    environment = "production"
    tier        = "connectivity"
    performance = "high"
  }
}
```

## VPN Gateway SKUs

### Basic SKU
- **Throughput**: 100 Mbps
- **Tunnels**: 10
- **BGP**: Not supported
- **Public IP**: Basic SKU (Dynamic)
- **Use Case**: Development, testing

### Standard SKUs
| SKU | Throughput | Tunnels | BGP | Generation |
|-----|------------|---------|-----|------------|
| VpnGw1 | 650 Mbps | 30 | Yes | Gen1/Gen2 |
| VpnGw2 | 1 Gbps | 30 | Yes | Gen1/Gen2 |
| VpnGw3 | 1.25 Gbps | 30 | Yes | Gen1/Gen2 |
| VpnGw4 | 5 Gbps | 100 | Yes | Gen2 only |
| VpnGw5 | 10 Gbps | 100 | Yes | Gen2 only |

### Availability Zone SKUs
- **VpnGw1AZ** through **VpnGw5AZ**
- Zone-redundant deployment
- Higher availability and resilience

## VPN Types

### Route-Based (Recommended)
- Dynamic routing protocols
- Multiple tunnels supported
- BGP support
- More flexible configuration

### Policy-Based
- Static routing
- Single tunnel
- Legacy compatibility
- Limited to Basic SKU

## IPSec/IKE Policies

### Default Policy
Azure uses default IPSec/IKE policies that work with most VPN devices.

### Custom Policy
For enhanced security or specific device requirements:

```hcl
ipsec_policy = {
  dh_group         = "DHGroup24"      # DHGroup14, DHGroup24, etc.
  ike_encryption   = "AES256"         # AES128, AES192, AES256
  ike_integrity    = "SHA384"         # SHA1, SHA256, SHA384
  ipsec_encryption = "AES256"         # AES128, AES192, AES256, GCMAES128, etc.
  ipsec_integrity  = "SHA256"         # SHA1, SHA256, GCMAES128, etc.
  pfs_group        = "PFS24"          # None, PFS1, PFS2, PFS14, PFS24, etc.
  sa_lifetime      = 7200             # 300-172800 seconds
}
```

## BGP Configuration

### BGP Settings
```hcl
bgp_settings = {
  asn         = 65515    # 1-4294967295 (avoid 65515 if using ExpressRoute)
  peer_weight = 0        # 0-100
}
```

### BGP Benefits
- Dynamic routing
- Automatic failover
- Route propagation
- Better for complex topologies

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpn_gateway_name | Name of the VPN Gateway | `string` | n/a | yes |
| resource_group_name | Name of the resource group for VPN resources | `string` | n/a | yes |
| location | Azure region where VPN resources will be created | `string` | n/a | yes |
| gateway_subnet_id | ID of the GatewaySubnet where VPN Gateway will be deployed | `string` | n/a | yes |
| local_network_gateway | Configuration for the local network gateway (on-premises) | `object` | n/a | yes |
| vpn_connection | Configuration for the VPN connection | `object` | n/a | yes |
| vpn_gateway_sku | SKU of the VPN Gateway | `string` | `"VpnGw1"` | no |
| vpn_gateway_generation | Generation of the VPN Gateway | `string` | `"Generation1"` | no |
| vpn_type | Type of VPN (RouteBased or PolicyBased) | `string` | `"RouteBased"` | no |
| enable_bgp | Enable BGP for the VPN Gateway | `bool` | `false` | no |
| bgp_settings | BGP settings for the VPN Gateway | `object` | `{asn=65515, peer_weight=0}` | no |
| tags | Tags to apply to VPN resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpn_gateway_id | ID of the VPN Gateway |
| vpn_gateway_name | Name of the VPN Gateway |
| vpn_gateway_public_ip | Public IP address of the VPN Gateway |
| vpn_gateway_public_ip_fqdn | FQDN of the VPN Gateway public IP |
| vpn_gateway_sku | SKU of the VPN Gateway |
| vpn_gateway_type | Type of the VPN Gateway |
| local_network_gateway_id | ID of the Local Network Gateway |
| local_network_gateway_name | Name of the Local Network Gateway |
| local_network_gateway_address | Gateway address of the Local Network Gateway |
| local_network_address_space | Address space of the Local Network Gateway |
| vpn_connection_id | ID of the VPN Connection |
| vpn_connection_name | Name of the VPN Connection |
| vpn_connection_status | Status of the VPN Connection |
| bgp_settings | BGP settings of the VPN Gateway (if BGP is enabled) |
| vpn_summary | Complete VPN summary |

## Examples

### Hub VPN Gateway (ALZ)

```hcl
module "hub_vpn" {
  source = "./modules/azure-vpn"

  vpn_gateway_name    = "vpn-gateway-hub"
  resource_group_name = "rg-hub-connectivity"
  location            = "West Europe"
  gateway_subnet_id   = module.hub_networking.subnet_ids["GatewaySubnet"]

  vpn_gateway_sku = "VpnGw1"
  vpn_type        = "RouteBased"
  enable_bgp      = false

  local_network_gateway = {
    name            = "local-gateway-headquarters"
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16", "10.10.0.0/16"]
  }

  vpn_connection = {
    name                = "vpn-connection-hq"
    shared_key          = var.vpn_shared_key
    connection_protocol = "IKEv2"
  }

  tags = {
    environment = "production"
    tier        = "connectivity"
    role        = "hub-vpn"
  }
}
```

### Branch Office VPN

```hcl
module "branch_vpn" {
  source = "./modules/azure-vpn"

  vpn_gateway_name    = "vpn-gateway-branch"
  resource_group_name = "rg-branch-connectivity"
  location            = "North Europe"
  gateway_subnet_id   = module.branch_networking.subnet_ids["GatewaySubnet"]

  vpn_gateway_sku = "Basic"  # Cost-effective for branch
  vpn_type        = "RouteBased"

  local_network_gateway = {
    name            = "local-gateway-branch"
    gateway_address = "203.0.113.100"
    address_space   = ["172.16.0.0/16"]
  }

  vpn_connection = {
    name       = "vpn-connection-branch"
    shared_key = var.branch_vpn_shared_key
  }

  tags = {
    environment = "production"
    tier        = "connectivity"
    role        = "branch-vpn"
    cost_center = "branch-operations"
  }
}
```

### Multi-Site VPN with BGP

```hcl
module "multisite_vpn" {
  source = "./modules/azure-vpn"

  vpn_gateway_name    = "vpn-gateway-multisite"
  resource_group_name = "rg-multisite-connectivity"
  location            = "West Europe"
  gateway_subnet_id   = module.multisite_networking.subnet_ids["GatewaySubnet"]

  vpn_gateway_sku = "VpnGw2"
  vpn_type        = "RouteBased"
  enable_bgp      = true

  bgp_settings = {
    asn         = 65001
    peer_weight = 10
  }

  local_network_gateway = {
    name            = "local-gateway-primary"
    gateway_address = "203.0.113.12"
    address_space   = ["192.168.0.0/16"]
  }

  vpn_connection = {
    name                = "vpn-connection-primary"
    shared_key          = var.primary_vpn_shared_key
    connection_protocol = "IKEv2"
    ipsec_policy = {
      dh_group         = "DHGroup14"
      ike_encryption   = "AES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "AES256"
      ipsec_integrity  = "SHA256"
      pfs_group        = "PFS14"
      sa_lifetime      = 3600
    }
  }

  tags = {
    environment = "production"
    tier        = "connectivity"
    role        = "multisite-vpn"
    bgp_enabled = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Resources

- `azurerm_public_ip.vpn_gateway`
- `azurerm_virtual_network_gateway.vpn_gateway`
- `azurerm_local_network_gateway.on_premises`
- `azurerm_virtual_network_gateway_connection.vpn_connection`

## Deployment Time

VPN Gateway creation typically takes:
- **Basic SKU**: 20-30 minutes
- **Standard SKUs**: 30-45 minutes
- **High-performance SKUs**: 45-60 minutes

The module includes extended timeouts to handle these long deployment times.

## Security Considerations

- **Shared Keys**: Use strong, unique shared keys (minimum 8 characters)
- **IPSec Policies**: Consider custom policies for enhanced security
- **BGP Security**: Implement BGP authentication when possible
- **Network Segmentation**: Use appropriate routing to limit access
- **Monitoring**: Enable VPN Gateway diagnostics and monitoring

## Cost Optimization

- **SKU Selection**: Choose appropriate SKU based on throughput requirements
- **Basic SKU**: Use for development/testing environments
- **Reserved Instances**: Consider reserved capacity for production gateways
- **Monitoring**: Monitor usage to optimize SKU selection

## Troubleshooting

### Common Issues

1. **Gateway Creation Timeout**: VPN Gateway creation can take up to 45 minutes
2. **BGP Configuration**: Ensure ASN numbers don't conflict with ExpressRoute
3. **IPSec Policy Mismatch**: Verify on-premises device supports selected policies
4. **Routing Issues**: Check route tables and BGP advertisements
5. **Connectivity Problems**: Verify shared keys and on-premises configuration

### Monitoring Commands

```bash
# Check VPN Gateway status
az network vnet-gateway show --name vpn-gateway-name --resource-group rg-name

# Check VPN connection status
az network vpn-connection show --name connection-name --resource-group rg-name

# View BGP peer status (if BGP enabled)
az network vnet-gateway list-bgp-peer-status --name vpn-gateway-name --resource-group rg-name
