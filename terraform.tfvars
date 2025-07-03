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
