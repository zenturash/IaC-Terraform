# Multi-Subscription ALZ Test Configuration
# This configuration tests the hub-spoke architecture across two subscriptions

# Architecture Mode - Enable ALZ Hub-Spoke
architecture_mode = "hub-spoke"

# Global settings
admin_username = "azureuser"
admin_password = "ComplexPassword123!"
location       = "West Europe"

# Multi-Subscription Configuration - YOUR SPECIFIC SUBSCRIPTIONS
subscriptions = {
  hub = "52bc998c-51a4-40fa-be04-26774b4c5f0e"    # Hub/Connectivity subscription
  spoke = {
    "test-workload" = "caaf1a53-3a0a-42e4-9688-4aac8f95a2d7"    # Test workload subscription
  }
}

# Component Deployment Control - Test Configuration
deploy_components = {
  vpn_gateway = false  # Disable VPN for initial test (can enable later)
  vms         = true   # Deploy test VM in spoke
  peering     = true   # Enable cross-subscription VNet peering
}

# Hub VNet Configuration (Deployed in Hub Subscription)
hub_vnet = {
  enabled             = true
  name               = "vnet-hub-test"
  resource_group_name = "rg-hub-test"
  cidr               = "10.1.0.0/20"
  location           = "West Europe"
  subnets            = ["GatewaySubnet", "ManagementSubnet"]  # Minimal subnets for testing
}

# Spoke VNets Configuration (Deployed in Spoke Subscription)
spoke_vnets = {
  "test-workload" = {
    enabled             = true
    name               = "vnet-spoke-test"
    resource_group_name = "rg-spoke-test"
    cidr               = "10.2.0.0/20"
    location           = "West Europe"
    subnets            = ["subnet-test", "subnet-app"]
    peer_to_hub        = true
    spoke_name          = "test-workload"  # Uses subscriptions.spoke["test-workload"]
  }
}

# VNet Peering Configuration - Cross-Subscription
vnet_peering = {
  enabled                    = true
  allow_virtual_network_access = true
  allow_forwarded_traffic    = true
  allow_gateway_transit      = true   # Hub can provide gateway services
  use_remote_gateways        = false  # Spoke doesn't use remote gateways (no VPN deployed yet)
}

# VPN Configuration (Disabled for initial test)
enable_vpn = true
vpn_configuration = {
  vpn_gateway_name = "vpn-gateway-test"
  vpn_gateway_sku  = "Basic"              # Cost-effective for testing
  vpn_type         = "RouteBased"
  enable_bgp       = false
  
  local_network_gateway = {
    name            = "local-gateway-test"
    gateway_address = "203.0.113.12"           # Placeholder IP
    address_space   = ["192.168.0.0/16"]       # Placeholder on-premises network
  }
  
  vpn_connection = {
    name                = "vpn-connection-test"
    shared_key          = "TestSharedKey123!"
    connection_protocol = "IKEv2"
  }
}

# Test Virtual Machine (Deployed in Spoke Subscription)
virtual_machines = {
  "test-vm-01" = {
    vm_size             = "Standard_B1s"        # Smallest/cheapest VM for testing
    subnet_name         = "subnet-test"
    resource_group_name = "rg-test-vm"
    enable_public_ip    = true                  # Enable for easy testing access
    os_disk_type        = "Standard_LRS"        # Cost-effective storage for testing
    spoke_name          = "test-workload"       # Deploy to test-workload spoke
    nsg_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"           # Allow from anywhere for testing (change to your IP for security)
        destination_address_prefix = "*"
      }
    ]
  }
}


# ========================================
# TESTING INSTRUCTIONS
# ========================================
#
# 1. AUTHENTICATION:
#    Ensure you're authenticated and have access to both subscriptions:
#    az login
#    az account list --output table
#    az account set --subscription "52bc998c-51a4-40fa-be04-26774b4c5f0e"  # Test hub access
#    az account set --subscription "caaf1a53-3a0a-42e4-9688-4aac8f95a2d7"  # Test spoke access
#
# 2. DEPLOY TEST:
#    cp terraform.tfvars.test terraform.tfvars
#    tofu init
#    tofu plan    # Review what will be deployed
#    tofu apply   # Deploy the test infrastructure
#
# 3. VALIDATE:
#    - Check hub VNet in hub subscription
#    - Check spoke VNet in spoke subscription  
#    - Verify VNet peering is established
#    - Test VM connectivity
#
# 4. CLEANUP:
#    tofu destroy  # Remove all test resources
#
# 5. ENABLE VPN (Optional):
#    Set deploy_components.vpn_gateway = true
#    Set enable_vpn = true
#    Update gateway_address with your actual public IP
#    tofu apply
#
# ========================================
# COST ESTIMATION (West Europe)
# ========================================
# - Hub VNet: Free
# - Spoke VNet: Free  
# - VNet Peering: ~$0.01/GB transferred
# - Test VM (B1s): ~$8/month
# - Public IP: ~$3/month
# - Storage (Standard_LRS): ~$2/month
# 
# Total estimated cost: ~$13/month for basic test setup
# VPN Gateway (if enabled): Additional ~$25/month for Basic SKU
# ========================================
