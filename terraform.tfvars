# Azure Multi-VM OpenTofu Configuration

# Global settings
admin_username = "azureuser"
admin_password = "ComplexPassword123!"
location       = "West Europe"

# Network configuration
vnet_cidr = "10.0.0.0/20"

# Define subnet names - CIDRs will be automatically calculated
# Note: Order matches current deployed subnets to avoid recreation
subnet_names = ["subnet-poc", "subnet-app", "subnet-mgmt"]

# Create a gateway subnet for VPN/ExpressRoute (will be placed at the end)
# Note: Disabled for now since changing existing subnet CIDRs requires VM recreation
create_gateway_subnet = true

# VPN Configuration - Basic Setup (change enable_vpn to true to deploy)
enable_vpn = true
vpn_configuration = {
  vpn_gateway_name = "vpn-gateway-basic"
  vpn_gateway_sku  = "Basic"              # Most cost-effective for POC
  vpn_type         = "RouteBased"         # Standard for most scenarios
  enable_bgp       = false                # Keep simple for basic setup
  
  local_network_gateway = {
    name            = "local-gateway-office"
    gateway_address = "203.0.113.12"           # Replace with YOUR actual public IP
    address_space   = ["192.168.0.0/16"]       # Replace with YOUR on-premises networks
  }
  
  vpn_connection = {
    name                = "vpn-connection-basic"
    shared_key          = "YourSecureSharedKey123!"  # Use a strong pre-shared key
    connection_protocol = "IKEv2"                     # Standard protocol
  }
}

# To enable VPN deployment:
# 1. Set enable_vpn = true
# 2. Replace gateway_address with your actual public IP
# 3. Replace address_space with your on-premises network CIDRs
# 4. Set a strong shared_key (must match your on-premises VPN device)
# 5. Run: tofu plan && tofu apply
# Note: VPN Gateway creation takes 30-45 minutes

# Define virtual machines with NSG rules
virtual_machines = {
  "poc-vm01" = {
    vm_size             = "Standard_B2s"
    subnet_name         = "subnet-poc"
    resource_group_name = "rg-poc"
    enable_public_ip    = false
    os_disk_type        = "Premium_LRS"
    # No NSG rules needed for private VM
  }
  "app-01" = {
    vm_size             = "Standard_D2s_v3"
    subnet_name         = "subnet-app"
    resource_group_name = "rg-app"
    enable_public_ip    = false
    os_disk_type        = "Premium_LRS"
    # No NSG rules needed for private VM
  }
  "mgmt-vm-01" = {
    vm_size             = "Standard_B2s"
    subnet_name         = "subnet-mgmt"
    resource_group_name = "rg-management"
    enable_public_ip    = true
    os_disk_type        = "Premium_LRS"
    nsg_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "93.161.18.8/32"  # Allow RDP only from your IP
        destination_address_prefix = "*"
      }
    ]
  }
}
