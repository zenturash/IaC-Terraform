# System Patterns - Azure VM OpenTofu Module

## Module Architecture Pattern
Following standard Terraform/OpenTofu module conventions:
- **Input Variables**: Defined in `variables.tf` with descriptions and defaults
- **Resource Definitions**: Organized in `main.tf` by resource type
- **Outputs**: Exposed in `outputs.tf` for consumption by calling code
- **Version Constraints**: Isolated in `versions.tf` for maintainability

## Resource Naming Convention
```
Pattern: {prefix}-{resource-type}-{identifier}
Examples:
- Resource Group: rg-{vm_name}-{random_suffix}
- Virtual Network: vnet-{vm_name}
- Subnet: subnet-{vm_name}
- Network Interface: nic-{vm_name}
- Public IP: pip-{vm_name}
- Virtual Machine: {vm_name}
```

## Tagging Strategy Pattern
Consistent tagging across all resources:
```hcl
locals {
  common_tags = {
    creation_date    = formatdate("YYYY-MM-DD", timestamp())
    creation_method  = "OpenTofu"
    os_type         = "Windows Server 2025"
    vm_size         = var.vm_size
    environment     = "POC"
    project         = "Azure VM POC"
  }
}
```

## Resource Dependencies
Clear dependency chain for proper creation order:
1. Resource Group (foundation)
2. Virtual Network (networking foundation)
3. Subnet (within VNet)
4. Public IP (if enabled)
5. Network Interface (depends on subnet and optional public IP)
6. Virtual Machine (depends on NIC)

## Configuration Patterns
### Variable Validation
```hcl
variable "vm_size" {
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_D2s_v3"
    ], var.vm_size)
    error_message = "VM size must be a valid Azure VM size."
  }
}
```

### Conditional Resources
```hcl
resource "azurerm_public_ip" "main" {
  count = var.enable_public_ip ? 1 : 0
  # resource configuration
}
```

## Data Source Patterns
Using data sources for dynamic configuration:
```hcl
data "azurerm_platform_image" "windows" {
  location  = var.location
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2025-Datacenter"
}
```

## Output Patterns
Exposing useful information for consumers:
- Resource IDs for integration
- IP addresses for connectivity
- Resource names for reference
- Connection information

## Error Handling Patterns
- Input validation at variable level
- Descriptive error messages
- Graceful handling of optional resources
- Clear dependency specifications

## Security Patterns
- No hardcoded secrets in code
- Password complexity validation
- Optional public access (default private)
- Minimal required permissions

## Modularity Patterns
- Self-contained module (creates own RG)
- Configurable but sensible defaults
- Clear input/output interface
- Reusable across environments

## Testing Patterns
- Example configurations for validation
- Multiple VM size scenarios
- Public/private IP variations
- Different naming conventions
