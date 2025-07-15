# OpenTofu Module Generalization Guide

A comprehensive guide for creating highly usable, secure, and flexible OpenTofu modules based on lessons learned from generalizing Azure VM and Networking modules.

## 🎯 Core Principles

### 1. Security-First Design
- **No automatic security rules** - Users must explicitly define what they want
- **Principle of least privilege** - Start with minimal access, add what's needed
- **Explicit over implicit** - No hidden assumptions about security requirements
- **User consciousness** - Force users to think about their security posture

### 2. Minimal Required Input
- **Identify true requirements** - Only variables that absolutely cannot have defaults
- **Smart defaults for everything else** - Sensible defaults that work in most scenarios
- **Progressive complexity** - Simple by default, powerful when needed

### 3. Maximum Flexibility
- **Every hardcoded value should be configurable** - What seems fixed today may need to change tomorrow
- **Comprehensive validation** - Prevent common misconfigurations with clear error messages
- **Multiple usage patterns** - Support simple POCs to complex production deployments

## 🏗️ Module Structure Best Practices

### Required Variables Section
```hcl
# ============================================================================
# REQUIRED VARIABLES
# ============================================================================

variable "resource_group_name" {
  description = "Name of the resource group for resources"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}
```

**Guidelines:**
- Keep required variables to absolute minimum (ideally 1-3)
- Always include validation rules
- Use clear, descriptive names
- Document why each variable is required

### Optional Variables with Smart Defaults
```hcl
# ============================================================================
# CORE CONFIGURATION (With Smart Defaults)
# ============================================================================

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "vm_name" {
  description = "Name of the virtual machine. If null, will auto-generate with random suffix"
  type        = string
  default     = null
  
  validation {
    condition     = var.vm_name == null || (length(var.vm_name) > 0 && length(var.vm_name) <= 64)
    error_message = "VM name must be between 1 and 64 characters when specified."
  }
}
```

**Guidelines:**
- Group related variables together
- Use null defaults for auto-generation scenarios
- Include validation even for optional variables
- Choose defaults that work for 80% of use cases

## 🔒 Security Implementation Patterns

### 1. Optional Security Features
```hcl
variable "create_nsg" {
  description = "Whether to create a Network Security Group"
  type        = bool
  default     = false  # Security features are opt-in
}

variable "nsg_rules" {
  description = "List of NSG rules to create"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []  # No default rules
}
```

### 2. Security Validation
```hcl
validation {
  condition = alltrue([
    for rule in var.nsg_rules : contains(["Inbound", "Outbound"], rule.direction)
  ])
  error_message = "NSG rule direction must be either 'Inbound' or 'Outbound'."
}

validation {
  condition = alltrue([
    for rule in var.nsg_rules : rule.priority >= 100 && rule.priority <= 4096
  ])
  error_message = "NSG rule priority must be between 100 and 4096."
}
```

## 🎨 Auto-Generation Patterns

### 1. Resource Naming with Random Suffixes
```hcl
# Random ID for unique resource naming
resource "random_id" "main" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
}

locals {
  # Generate unique suffix for resource names
  random_suffix = var.use_random_suffix ? random_id.main[0].hex : ""
  suffix = var.use_random_suffix ? "-${local.random_suffix}" : ""
  
  # Determine VM name (auto-generate if not provided)
  vm_name = var.vm_name != null ? var.vm_name : "vm${local.suffix}"
}
```

### 2. Auto-Generated Passwords
```hcl
# Random password generation if not provided
resource "random_password" "admin_password" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

locals {
  # Determine admin password (use provided or generated)
  admin_password = var.admin_password != null ? var.admin_password : random_password.admin_password[0].result
}
```

## 📊 Comprehensive Outputs

### 1. Core Information Outputs
```hcl
output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}
```

### 2. Connection Information
```hcl
output "rdp_connection_string" {
  description = "RDP connection string for the virtual machine"
  value = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
}

output "connection_guide" {
  description = "Quick guide for connecting to the virtual machine"
  value = {
    rdp_command = var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : "mstsc /v:${azurerm_network_interface.main.private_ip_address}"
    username = azurerm_windows_virtual_machine.main.admin_username
    security_note = var.create_nsg ? "NSG is enabled - check nsg_rules for specific access rules" : "No NSG configured - using subnet-level security"
  }
}
```

### 3. Summary Outputs
```hcl
output "vm_summary" {
  description = "Comprehensive summary of the virtual machine"
  value = {
    vm_name           = azurerm_windows_virtual_machine.main.name
    vm_size           = azurerm_windows_virtual_machine.main.size
    private_ip        = azurerm_network_interface.main.private_ip_address
    public_ip         = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
    nsg_enabled       = var.create_nsg
    password_auto_generated = var.admin_password == null
  }
}
```

## 🏷️ Auto-Tagging Patterns

### 1. Comprehensive Auto-Tagging
```hcl
locals {
  # Comprehensive tagging
  base_tags = var.enable_auto_tagging ? {
    vm_name           = local.vm_name
    vm_size           = var.vm_size
    creation_date     = formatdate("YYYY-MM-DD", timestamp())
    creation_time     = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    creation_method   = "OpenTofu"
    location          = var.location
    auto_generated    = var.vm_name == null || var.admin_password == null
  } : {}
  
  # Merge all tags
  common_tags = merge(local.base_tags, var.tags)
}
```

### 2. Configurable Tagging
```hcl
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_auto_tagging" {
  description = "Whether to automatically add comprehensive tags"
  type        = bool
  default     = true
}
```

## 📚 Documentation Best Practices

### 1. Clear Usage Examples
```markdown
### Minimal Usage (Only required variables)

```hcl
module "simple_vm" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.subnet_id
  resource_group_name = "rg-vm-prod"
}
```

**What you get:**
- VM with auto-generated name
- Auto-generated secure password
- No public IP (private only)
- No NSG (uses subnet-level security)
```

### 2. Security-Focused Examples
```markdown
### 1. VM without NSG (Recommended for Internal VMs)

```hcl
module "internal_vm" {
  source = "./modules/azure-vm"
  
  subnet_id = var.internal_subnet_id
  vm_name   = "app-server-01"
  # create_nsg = false (this is the default)
}
```

**Security posture:**
- No NSG created at VM level
- Relies entirely on subnet-level security
- Most secure and recommended approach
```

### 3. Variable Documentation Tables
```markdown
### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `subnet_id` | ID of the subnet where the VM will be deployed | `string` |
| `resource_group_name` | Name for the resource group | `string` |

### Security Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_nsg` | Whether to create a Network Security Group | `bool` | `false` |
| `nsg_rules` | List of NSG rules to create | `list(object)` | `[]` |
```

## 🔄 Migration and Backward Compatibility

### 1. Migration Documentation
```markdown
## Migration from Previous Version

If you're upgrading from the previous version:

1. **NSG behavior changed**: NSG is now optional and independent
2. **No automatic rules**: You must explicitly define security rules
3. **More variables available**: Many hardcoded values are now configurable

### Example Migration

**Old approach:**
```hcl
module "vm" {
  source = "./modules/azure-vm"
  
  vm_name      = "my-vm"
  subnet_id    = var.subnet_id
  enable_public_ip = true
}
```

**New approach (equivalent):**
```hcl
module "vm" {
  source = "./modules/azure-vm"
  
  vm_name          = "my-vm"
  subnet_id        = var.subnet_id
  resource_group_name = "rg-vm-prod"  # Now required
  enable_public_ip = true
  create_nsg       = true  # Now explicit
  
  # Must explicitly define security rules
  nsg_rules = [
    {
      name                       = "AllowRDP"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "YOUR.IP.RANGE/24"
      destination_address_prefix = "*"
    }
  ]
}
```
```

## 🚨 Common Pitfalls to Avoid

### 1. Security Anti-Patterns
❌ **Don't do this:**
```hcl
# Automatic RDP rule creation
resource "azurerm_network_security_rule" "allow_rdp" {
  count = var.enable_public_ip ? 1 : 0  # Automatic based on public IP
  # ... automatic rule configuration
}
```

✅ **Do this instead:**
```hcl
# Explicit rule creation only when requested
resource "azurerm_network_security_rule" "rules" {
  count = var.create_nsg ? length(var.nsg_rules) : 0
  # ... explicit rule configuration from user input
}
```

### 2. Variable Design Anti-Patterns
❌ **Don't do this:**
```hcl
variable "vm_config" {
  description = "VM configuration"
  type = object({
    name = string
    size = string
    # ... many nested properties
  })
}
```

✅ **Do this instead:**
```hcl
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = null
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}
```

### 3. Output Anti-Patterns
❌ **Don't do this:**
```hcl
output "vm_info" {
  value = azurerm_windows_virtual_machine.main
}
```

✅ **Do this instead:**
```hcl
output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}
```

## 🎯 Module Testing Strategy

### 1. Minimal Configuration Test
```hcl
module "minimal_test" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.test_subnet_id
  resource_group_name = "rg-test-minimal"
}
```

### 2. Full Configuration Test
```hcl
module "full_test" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.test_subnet_id
  resource_group_name = "rg-test-full"
  vm_name            = "test-vm-full"
  enable_public_ip   = true
  create_nsg         = true
  
  nsg_rules = [
    {
      name                       = "TestRule"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
```

### 3. Multiple Instance Test
```hcl
module "multi_test_1" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.test_subnet_id
  resource_group_name = "rg-test-multi-1"
  vm_name            = "test-vm-1"
}

module "multi_test_2" {
  source = "./modules/azure-vm"
  
  subnet_id           = var.test_subnet_id
  resource_group_name = "rg-test-multi-2"
  vm_name            = "test-vm-2"
}
```

## 📋 Generalization Checklist

### Before Starting
- [ ] Identify all hardcoded values in the module
- [ ] List current required variables
- [ ] Document existing security assumptions
- [ ] Review user feedback and common customization requests

### Variable Design
- [ ] Minimize required variables (aim for 1-3)
- [ ] Add comprehensive validation rules
- [ ] Use null defaults for auto-generation scenarios
- [ ] Group related variables logically
- [ ] Add clear descriptions and examples

### Security Review
- [ ] Remove all automatic security rules
- [ ] Make security features explicitly opt-in
- [ ] Add validation for security configurations
- [ ] Document security implications clearly
- [ ] Provide security-focused examples

### Auto-Generation Features
- [ ] Implement random suffix generation
- [ ] Add auto-password generation
- [ ] Create smart naming patterns
- [ ] Make auto-generation configurable
- [ ] Test uniqueness across multiple instances

### Output Enhancement
- [ ] Add comprehensive core outputs
- [ ] Include connection information
- [ ] Create summary outputs
- [ ] Add deployment information
- [ ] Document all outputs clearly

### Documentation Update
- [ ] Create minimal usage examples
- [ ] Add security-focused examples
- [ ] Document all variables in tables
- [ ] Provide migration guide
- [ ] Include use case examples
- [ ] Add troubleshooting section

### Testing
- [ ] Test minimal configuration
- [ ] Test full configuration
- [ ] Test multiple instances
- [ ] Validate all security scenarios
- [ ] Test auto-generation features
- [ ] Verify backward compatibility

## 🏆 Success Metrics

A well-generalized module should achieve:

### Usability
- **Minimal barrier to entry**: Works with 1-3 required variables
- **Progressive complexity**: Simple by default, powerful when needed
- **Clear documentation**: Users understand what they're getting
- **Predictable behavior**: No surprises or hidden assumptions

### Security
- **Explicit security**: No automatic security rules
- **User awareness**: Forces conscious security decisions
- **Comprehensive validation**: Prevents common misconfigurations
- **Clear security posture**: Users understand their security stance

### Flexibility
- **Configurable everything**: No hardcoded values
- **Multiple patterns**: Supports various use cases
- **Auto-generation**: Reduces naming conflicts
- **Extensible**: Easy to add new features

### Maintainability
- **Clear structure**: Well-organized variable sections
- **Comprehensive validation**: Catches errors early
- **Good documentation**: Easy for others to understand and contribute
- **Backward compatibility**: Doesn't break existing usage

## 🎓 Key Lessons Learned

1. **Security should never be automatic** - Users must consciously choose their security posture
2. **Defaults should work for 80% of cases** - But everything should be configurable
3. **Auto-generation prevents conflicts** - Essential for multiple instance deployments
4. **Validation prevents pain** - Catch configuration errors early with clear messages
5. **Documentation is crucial** - Examples are more valuable than parameter lists
6. **Migration paths matter** - Help users transition from old to new patterns
7. **Testing multiple scenarios** - Minimal, full, and multi-instance configurations
8. **Outputs should be comprehensive** - Include connection info and summaries

By following these patterns and principles, you can create OpenTofu modules that are secure by default, easy to use, and flexible enough to handle complex production scenarios while remaining simple for POCs and development work.
