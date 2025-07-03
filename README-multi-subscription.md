# Multi-Subscription Azure Landing Zone (ALZ) Deployment

This document explains how to deploy the Azure Landing Zone (ALZ) across multiple Azure subscriptions using the OpenTofu module.

## 🏗️ Multi-Subscription Architecture

### Subscription Strategy
- **Hub Subscription**: Contains connectivity resources (VPN Gateway, ExpressRoute, Azure Firewall)
- **Spoke Subscription(s)**: Contains workload resources (VMs, applications, databases)

### Benefits
- **Cost Management**: Separate billing and cost allocation
- **Security Isolation**: Different security boundaries and access controls
- **Compliance**: Meet regulatory requirements for resource separation
- **Management**: Different teams can manage different subscriptions

## 🔧 Configuration

### Subscription Configuration
Configure the subscription IDs in your `terraform.tfvars` file:

```hcl
# Multi-Subscription Configuration
subscriptions = {
  hub_subscription_id   = "12345678-1234-1234-1234-123456789abc"    # Connectivity subscription
  spoke_subscription_id = "87654321-4321-4321-4321-cba987654321"    # Workload subscription
}
```

### Single Subscription Deployment
For single subscription deployment, leave both values as `null`:

```hcl
# Single Subscription Configuration
subscriptions = {
  hub_subscription_id   = null  # Uses default authenticated subscription
  spoke_subscription_id = null  # Uses default authenticated subscription
}
```

## 🚀 Deployment Examples

### Example 1: Multi-Subscription Hub-Spoke ALZ

```hcl
# terraform.tfvars
architecture_mode = "hub-spoke"

# Multi-subscription configuration
subscriptions = {
  hub_subscription_id   = "connectivity-sub-id"
  spoke_subscription_id = "workload-sub-id"
}

# Hub VNet (deployed in connectivity subscription)
hub_vnet = {
  enabled             = true
  name               = "vnet-hub-connectivity"
  resource_group_name = "rg-hub-connectivity"
  cidr               = "10.1.0.0/20"
  location           = "West Europe"
  subnets            = ["GatewaySubnet", "AzureFirewallSubnet", "ManagementSubnet"]
}

# Spoke VNet (deployed in workload subscription)
spoke_vnets = {
  "production" = {
    enabled             = true
    name               = "vnet-spoke-production"
    resource_group_name = "rg-spoke-production"
    cidr               = "10.2.0.0/20"
    location           = "West Europe"
    subnets            = ["subnet-web", "subnet-app", "subnet-db"]
    peer_to_hub        = true
  }
}

# VPN Gateway (deployed in hub/connectivity subscription)
deploy_components = {
  vpn_gateway = true   # Deployed in hub subscription
  vms         = true   # Deployed in spoke subscription
  peering     = true   # Cross-subscription peering
}

# VMs (deployed in workload subscription)
virtual_machines = {
  "web-vm-01" = {
    vm_size             = "Standard_D2s_v3"
    subnet_name         = "subnet-web"
    resource_group_name = "rg-production-web"
    enable_public_ip    = false
    os_disk_type        = "Premium_LRS"
  }
}
```

### Example 2: Single Subscription Hub-Spoke

```hcl
# terraform.tfvars
architecture_mode = "hub-spoke"

# Single subscription (uses authenticated subscription for both)
subscriptions = {
  hub_subscription_id   = null
  spoke_subscription_id = null
}

# Rest of configuration remains the same...
```

## 🔐 Authentication & Permissions

### Required Permissions

#### Hub Subscription
- **Contributor** or **Owner** role
- Permissions to create:
  - Resource Groups
  - Virtual Networks
  - VPN Gateways
  - Public IPs
  - Network Security Groups

#### Spoke Subscription
- **Contributor** or **Owner** role
- Permissions to create:
  - Resource Groups
  - Virtual Networks
  - Virtual Machines
  - Storage Accounts
  - Network Interfaces

#### Cross-Subscription Peering
- **Network Contributor** role on both subscriptions
- Or custom role with `Microsoft.Network/virtualNetworks/virtualNetworkPeerings/*` permissions

### Authentication Methods

#### Option 1: Azure CLI (Recommended for Development)
```bash
# Authenticate with Azure CLI
az login

# Verify access to both subscriptions
az account list --output table
az account set --subscription "hub-subscription-id"
az account set --subscription "spoke-subscription-id"
```

#### Option 2: Service Principal (Recommended for Production)
```bash
# Create service principal with access to both subscriptions
az ad sp create-for-rbac --name "alz-deployment-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/hub-sub-id" "/subscriptions/spoke-sub-id"

# Set environment variables
export ARM_CLIENT_ID="service-principal-app-id"
export ARM_CLIENT_SECRET="service-principal-password"
export ARM_TENANT_ID="tenant-id"
```

## 📊 Resource Deployment Matrix

| Resource Type | Single VNet | Hub-Spoke (Same Sub) | Hub-Spoke (Multi-Sub) |
|---------------|-------------|---------------------|----------------------|
| Hub VNet | N/A | Default Subscription | Hub Subscription |
| Spoke VNet | N/A | Default Subscription | Spoke Subscription |
| VPN Gateway | Default Subscription | Default Subscription | Hub Subscription |
| Virtual Machines | Default Subscription | Default Subscription | Spoke Subscription |
| VNet Peering | N/A | Same Subscription | Cross-Subscription |

## 🔍 Validation & Testing

### Pre-Deployment Validation
```bash
# Validate configuration
tofu validate

# Plan deployment (review resources and subscriptions)
tofu plan

# Check which subscription each resource will be deployed to
tofu plan | grep -E "(subscription|provider)"
```

### Post-Deployment Verification
```bash
# Check hub resources
az network vnet list --subscription "hub-subscription-id" --output table

# Check spoke resources
az vm list --subscription "spoke-subscription-id" --output table

# Verify VNet peering
az network vnet peering list \
  --resource-group "rg-hub-connectivity" \
  --vnet-name "vnet-hub-connectivity" \
  --subscription "hub-subscription-id"
```

## 🚨 Common Issues & Solutions

### Issue 1: Cross-Subscription Peering Fails
**Symptoms**: Peering creation fails with permission errors
**Solution**: 
- Ensure service principal has Network Contributor role on both subscriptions
- Verify subscription IDs are correct
- Check that both VNets exist before creating peering

### Issue 2: Provider Authentication Errors
**Symptoms**: "Invalid subscription ID" or authentication failures
**Solution**:
- Verify subscription IDs are correct and accessible
- Ensure authenticated account has access to both subscriptions
- Check that subscriptions are active and not disabled

### Issue 3: Resource Group Creation Fails
**Symptoms**: Cannot create resource groups in target subscription
**Solution**:
- Verify Contributor role on target subscription
- Check subscription limits and quotas
- Ensure subscription is not locked

## 📈 Cost Optimization

### Multi-Subscription Benefits
- **Separate Billing**: Track costs per workload/environment
- **Budget Controls**: Set different budgets for hub vs spoke
- **Reserved Instances**: Optimize RI purchases per subscription
- **Cost Allocation**: Charge back to different business units

### Example Cost Structure
```
Hub Subscription (Connectivity):
├── VPN Gateway: $150/month
├── Public IPs: $5/month
└── Network bandwidth: Variable

Spoke Subscription (Workloads):
├── Virtual Machines: $500/month
├── Storage: $100/month
└── Network bandwidth: Variable
```

## 🔄 Migration Scenarios

### From Single to Multi-Subscription
1. **Plan**: Identify resources to move
2. **Backup**: Export current state
3. **Deploy**: Create new multi-subscription configuration
4. **Migrate**: Move workloads to new spoke subscription
5. **Cleanup**: Remove old single-subscription resources

### Between Subscriptions
1. **Export**: Use `az resource list` to inventory resources
2. **Recreate**: Deploy in target subscription
3. **Data Migration**: Move data between subscriptions
4. **DNS Updates**: Update any DNS records
5. **Validation**: Test connectivity and functionality

## 📚 Additional Resources

- [Azure Landing Zone Documentation](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Subscription Management](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/)
- [VNet Peering Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
