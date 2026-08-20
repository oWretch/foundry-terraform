data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

locals {
  initial_suffix      = substr(md5("${data.azurerm_subscription.current.subscription_id}:${var.prefix}"), 0, 4)
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.prefix}-${local.initial_suffix}"
  suffix              = var.random_suffix != "" ? var.random_suffix : substr(md5("${data.azurerm_subscription.current.subscription_id}:${local.resource_group_name}"), 0, 4)

  ai_services_name = "${var.ai_services_name_base}${local.suffix}"
  ai_search_name   = "${var.ai_search_name_base}${local.suffix}"
  cosmosdb_name    = "${var.cosmosdb_name_base}${local.suffix}"
  storage_name     = lower("${var.storage_name_base}${local.suffix}")
  acr_name         = lower("acr${local.suffix}")

  hub_subnets = {
    AzureFirewallSubnet           = cidrsubnet(var.hub_vnet_prefix, 3, 0)
    AzureBastionSubnet            = cidrsubnet(var.hub_vnet_prefix, 3, 1)
    GatewaySubnet                 = cidrsubnet(var.hub_vnet_prefix, 3, 2)
    AzureFirewallManagementSubnet = cidrsubnet(var.hub_vnet_prefix, 3, 3)
  }
  vm_subnet_prefix     = cidrsubnet(var.vm_vnet_prefix, 3, 0)
  pe_subnet_prefix     = cidrsubnet(var.aiapp_vnet_prefix, 3, 0)
  agents_subnet_prefix = cidrsubnet(var.aiapp_vnet_prefix, 3, 4)
  mcp_subnet_prefix    = cidrsubnet(var.aiapp_vnet_prefix, 3, 5)
}