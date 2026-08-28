variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "australiaeast"
}

variable "prefix" {
  description = "Lowercase alphanumeric naming prefix."
  type        = string
  default     = "aifoundrybicep"

  validation {
    condition     = can(regex("^[a-z0-9]{3,16}$", var.prefix))
    error_message = "prefix must contain 3-16 lowercase alphanumeric characters."
  }
}

variable "random_suffix" {
  description = "Optional four-character lowercase alphanumeric naming suffix."
  type        = string
  default     = ""

  validation {
    condition     = var.random_suffix == "" || can(regex("^[a-z0-9]{4}$", var.random_suffix))
    error_message = "random_suffix must be empty or exactly four lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Optional resource group name. A deterministic name is generated when empty."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to resources that support tags."
  type        = map(string)
  default = {
    lab       = "foundry-terraform"
    managedBy = "terraform"
  }
}

variable "hub_vnet_prefix" {
  type        = string
  description = "Hub VNet /23 CIDR."
  default     = "10.100.0.0/23"
  validation {
    condition     = can(cidrsubnet(var.hub_vnet_prefix, 0, 0)) && tonumber(split("/", var.hub_vnet_prefix)[1]) == 23
    error_message = "hub_vnet_prefix must be a valid /23 CIDR."
  }
}

variable "vm_vnet_prefix" {
  type        = string
  description = "VM spoke VNet /23 CIDR."
  default     = "10.10.10.0/23"
  validation {
    condition     = can(cidrsubnet(var.vm_vnet_prefix, 0, 0)) && tonumber(split("/", var.vm_vnet_prefix)[1]) == 23
    error_message = "vm_vnet_prefix must be a valid /23 CIDR."
  }
}

variable "aiapp_vnet_prefix" {
  type        = string
  description = "AI application spoke VNet /23 CIDR."
  default     = "10.10.20.0/23"
  validation {
    condition     = can(cidrsubnet(var.aiapp_vnet_prefix, 0, 0)) && tonumber(split("/", var.aiapp_vnet_prefix)[1]) == 23
    error_message = "aiapp_vnet_prefix must be a valid /23 CIDR."
  }
}

variable "firewall_enabled" {
  type    = bool
  default = true
}

variable "bastion_enabled" {
  type    = bool
  default = true
}

variable "vm_enabled" {
  type    = bool
  default = true
}

variable "container_registry_enabled" {
  type    = bool
  default = true
}

variable "firewall_sku_tier" {
  type    = string
  default = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be Basic, Standard, or Premium."
  }
}

variable "bastion_sku" {
  type    = string
  default = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium", "Developer"], var.bastion_sku)
    error_message = "bastion_sku must be Basic, Standard, Premium, or Developer."
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_D8s_v5"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}
variable "admin_password" {
  description = "Local administrator password for the optional jump box."
  type        = string
  sensitive   = true
  default     = null
  validation {
    condition     = !var.vm_enabled || (var.admin_password != null && length(var.admin_password) >= 12)
    error_message = "admin_password must be at least 12 characters when vm_enabled is true."
  }
}

variable "os_disk_type" {
  type    = string
  default = "Premium_LRS"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "PremiumV2_LRS", "UltraSSD_LRS"], var.os_disk_type)
    error_message = "os_disk_type is not supported by this configuration."
  }
}

variable "developer_ip_cidr" {
  description = "Optional CIDR allowed to push to ACR. Empty keeps ACR private-only."
  type        = string
  default     = ""
  validation {
    condition     = var.developer_ip_cidr == "" || can(cidrhost(var.developer_ip_cidr, 0))
    error_message = "developer_ip_cidr must be empty or a valid CIDR."
  }
}

variable "private_dns_zones" {
  type        = set(string)
  description = "Private DNS zones linked to all three VNets."
  default = [
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.services.ai.azure.com",
    "privatelink.blob.core.windows.net",
    "privatelink.search.windows.net",
    "privatelink.documents.azure.com",
    "privatelink.azurecr.io"
  ]
}

variable "ai_services_name_base" {
  type    = string
  default = "aiservices"
}

variable "ai_search_name_base" {
  type    = string
  default = "aisearch"
}

variable "cosmosdb_name_base" {
  type    = string
  default = "cosmosdb"
}

variable "storage_name_base" {
  type    = string
  default = "foundrystg"
}

variable "project_name" {
  type    = string
  default = "project"
}

variable "project_description" {
  type    = string
  default = "A project for the AI Foundry account with network secured deployed Agent"
}

variable "project_display_name" {
  type    = string
  default = "network secured agent project"
}

variable "project_capability_host_name" {
  type    = string
  default = "caphostproj"
}

variable "model_name" {
  type    = string
  default = "gpt-4.1-mini"
}

variable "model_format" {
  type    = string
  default = "OpenAI"
}

variable "model_version" {
  type    = string
  default = "2025-04-14"
}

variable "model_sku_name" {
  type    = string
  default = "GlobalStandard"
}
variable "model_capacity" {
  type    = number
  default = 30
  validation {
    condition     = var.model_capacity > 0
    error_message = "model_capacity must be greater than zero."
  }
}

variable "network_injection_enabled" {
  type    = bool
  default = true
}
variable "diagnostic_retention_days" {
  type    = number
  default = 30
  validation {
    condition     = var.diagnostic_retention_days >= 30 && var.diagnostic_retention_days <= 730
    error_message = "diagnostic_retention_days must be between 30 and 730."
  }
}
