# Multi-Subscription ALZ Test Configuration
# This configuration tests the hub-spoke architecture across two subscriptions

# Architecture Mode - Enable ALZ Hub-Spoke
architecture_mode = "hub-spoke"

# Global settings
admin_username = "azureuser"
admin_password = "ComplexPassword123!"
# location = "West Europe" # Uses module default

# Global Tags - Applied to all resources
global_tags = {
  environment     = "Test"
  project         = "Azure ALZ Multi-Subscription Test"
  creation_method = "OpenTofu"
  owner           = "Zentura"
  cost_center     = "1001"
}

# Multi-Subscription Configuration - YOUR SPECIFIC SUBSCRIPTIONS
subscriptions = {
  hub = "52bc998c-51a4-40fa-be04-26774b4c5f0e"    # Hub/Connectivity subscription
  spoke = {
    "test-workload" = "caaf1a53-3a0a-42e4-9688-4aac8f95a2d7"    # Test workload subscription
  }
}

# Component Deployment Control - Test Configuration
deploy_components = {
  vpn_gateway     = false   # Disable VPN for initial test (can enable later)
  vms             = true    # Deploy test VM in spoke
  peering         = true    # Enable cross-subscription VNet peering
  backup_services = true    # Enable backup services for testing
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
# Most settings use ALZ-optimized defaults from the module, only override what's needed
vnet_peering = {
  enabled             = true
  use_remote_gateways = false  # Override default: Spoke doesn't use remote gateways (no VPN deployed yet)
  # Other settings use module defaults:
  # allow_virtual_network_access = true (default)
  # allow_forwarded_traffic = true (default) 
  # allow_gateway_transit = true (default)
}

# VPN Configuration (Controlled by deploy_components.vpn_gateway)
# Optimized to use module defaults where possible
vpn_configuration = {
  # VPN Gateway configuration
  vpn_gateway_name = "vpn-gateway-test"
  vpn_gateway_sku  = "Basic"              # Override default (VpnGw1) for cost-effective testing
  # vpn_type = "RouteBased" (default)
  # enable_bgp = false (default)
  
  # Local Network Gateway configuration (optional - null means gateway-only mode)
  local_network_gateway = {
    name            = "local-gateway-test"      # Optional - will auto-generate if null
    gateway_address = "203.0.113.12"           # Required - Placeholder IP
    address_space   = ["192.168.0.0/16"]       # Required - Placeholder on-premises network
  }
  
  # VPN Connection configuration (optional - null means no connection)
  vpn_connection = {
    name       = "vpn-connection-test" # Optional - will auto-generate if null
    shared_key = "TestSharedKey123!"  # Required - Pre-shared key
    # connection_protocol = "IKEv2" (default)
  }
}

# Test Virtual Machines (Deployed in Spoke Subscription)
# Optimized to use module defaults where possible
virtual_machines = {
  "test-vm-01" = {
    # vm_size = "Standard_B2s" (default)
    subnet_name         = "subnet-test"
    resource_group_name = "rg-test-vm"
    enable_public_ip    = true                  # Override default (false) for easy testing access
    os_disk_type        = "Standard_LRS"        # Override default (Premium_LRS) for cost-effective testing
    spoke_name          = "test-workload"       # Deploy to test-workload spoke
    
    # admin_username = null (uses global)
    # admin_password = null (uses global)
    
    # NSG rules (generalized module will create NSG only if rules are provided)
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
  "test-vm-02" = {
    # vm_size = "Standard_B2s" (default)
    subnet_name         = "subnet-test"
    resource_group_name = "rg-test-vm2"
    enable_public_ip    = true                  # Override default (false) for easy testing access
    os_disk_type        = "Standard_LRS"        # Override default (Premium_LRS) for cost-effective testing
    spoke_name          = "test-workload"       # Deploy to test-workload spoke
    
    # admin_username = null (uses global)
    # admin_password = null (uses global)
    
    # NSG rules (generalized module will create NSG only if rules are provided)
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

# SQL Server Virtual Machines (Test SQL Server Module)
sql_server_vms = {
  "sql-test-01" = {
    # Required variables
    subnet_name         = "subnet-app"  # Deploy to app subnet in spoke
    resource_group_name = "rg-sql-test"
    admin_username      = "azureuser"   # Uses global admin_username
    admin_password      = "ComplexPassword123!"  # Uses global admin_password
    
    # Optional configuration - using defaults where possible
    vm_size        = "Standard_D4s_v3"  # SQL Server optimized size
    sql_edition    = "Standard"         # SQL Server Standard edition
    spoke_name     = "test-workload"    # Deploy to test-workload spoke
    
    # Storage configuration - using module defaults
    # data_disk_config uses default: 100GB Premium_LRS with ReadOnly caching
    # log_disk_config uses default: 50GB Premium_LRS with None caching
    
    # Network configuration
    enable_public_ip = true   # Enable for testing (change to false for production)
    create_nsg       = true   # Create NSG with explicit rules
    
    # SQL Server security rules
    sql_nsg_rules = [
      {
        name                       = "AllowSQLFromApp"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.2.0.0/24"  # Allow from subnet-test
        destination_address_prefix = "*"
      },
      {
        name                       = "AllowRDPFromOffice"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"  # Allow from anywhere for testing
        destination_address_prefix = "*"
      }
    ]
    
    # Tags
    tags = {
      role        = "database"
      environment = "test"
      sql_edition = "standard"
    }
  }
}

# Backup Services Configuration (Test Backup Module)
backup_configuration = {
  # Required configuration
  resource_group_name = "rg-backup-test"
  
  # Backup policies configuration (security-first: opt-in for testing)
  policies = {
    vm_daily       = true   # Enable VM daily backup policy for testing
    vm_enhanced    = false  # Disable enhanced hourly VM backups (can be enabled later)
    files_daily    = false  # Disable Azure Files backup for testing
    blob_daily     = false  # Disable Blob backup for testing
    sql_hourly_log = false  # Disable SQL Server backup for testing
  }
  
  # VM backup configuration (ARM template defaults)
  vm_backup_time           = "02:00"                    # 2 AM UTC backup time for testing
  vm_backup_retention_days = 7                         # 7-day retention for cost-effective testing
  vm_backup_timezone       = "Romance Standard Time"   # Central European Time (ARM default)
  
  # Files backup configuration (ARM template defaults)
  files_backup_time           = "02:30"                # 2:30 AM UTC backup time
  files_backup_retention_days = 7                      # 7-day retention for testing
  
  # Blob backup configuration (ARM template defaults)
  blob_backup_retention_days = 7                       # 7-day retention for testing
  
  # SQL backup configuration (ARM template defaults)
  sql_full_backup_time           = "03:00"             # 3 AM UTC full backups
  sql_full_backup_retention_days = 7                   # 7-day retention for testing
  sql_log_backup_frequency_minutes = 60                # Hourly log backups (ARM default)
  sql_log_backup_retention_days  = 7                   # 7-day log retention for testing
  
  # Alert configuration (ARM template defaults)
  enable_backup_alerts = true                          # Enable backup alerts for testing
  alert_send_to_owners = "DoNotSend"                   # Don't send to owners (ARM default)
  alert_custom_email_addresses = [                     # Test email addresses
    "backup-test@zentura.com"
  ]
  
  # Custom backup policies (for advanced scenarios not covered by predefined policies)
  custom_backup_policies = {
    # Example 1: Weekly VM backup with yearly retention
    "weekly-vm-with-yearly" = {
      policy_type = "vm"
      vault_type  = "recovery_vault"
      name        = "WeeklyVMWithYearly"
      description = "Weekly VM backup with 7-year yearly retention"
      
      vm_policy = {
        policy_type                    = "V1"
        timezone                      = "Romance Standard Time"
        instant_restore_retention_days = 2
        backup_frequency              = "Weekly"
        backup_weekdays               = ["Sunday"]
        backup_time                   = "03:00"
        
        # Retention configuration
        daily_retention_days     = 0   # No daily retention
        weekly_retention_weeks   = 12  # 12 weeks
        monthly_retention_months = 12  # 12 months
        yearly_retention_years   = 7   # 7 years
      }
      
      tags = {
        policy_type = "long-term"
        environment = "test"
      }
    }
    
    # Example 2: Custom SQL Server backup with 15-minute log frequency
    "custom-sql-frequent-logs" = {
      policy_type = "vm_workload"
      vault_type  = "recovery_vault"
      name        = "CustomSQLFrequentLogs"
      description = "SQL Server backup with 15-minute log backups"
      
      vm_workload_policy = {
        workload_type       = "SQLDataBase"
        timezone           = "Romance Standard Time"
        compression_enabled = true
        
        protection_policies = [
          {
            policy_type      = "Full"
            backup_frequency = "Daily"
            backup_time      = "02:00"
            retention_days   = 30
          },
          {
            policy_type          = "Log"
            frequency_in_minutes = 15  # Every 15 minutes
            retention_days       = 7
          }
        ]
      }
      
      tags = {
        policy_type = "high-frequency"
        workload    = "sql-server"
      }
    }
    
    # Example 3: Long-term blob storage backup
    "blob-long-term" = {
      policy_type = "blob_storage"
      vault_type  = "backup_vault"
      name        = "BlobLongTerm90Days"
      description = "Blob storage backup with 90-day retention"
      
      blob_policy = {
        retention_days = 90
      }
      
      tags = {
        policy_type = "long-term"
        storage     = "blob"
      }
    }
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
