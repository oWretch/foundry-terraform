resource "azurerm_container_registry" "main" {
  count                         = var.container_registry_enabled ? 1 : 0
  name                          = local.acr_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = var.developer_ip_cidr != ""
  network_rule_bypass_option    = "AzureServices"
  tags                          = var.tags

  dynamic "network_rule_set" {
    for_each = var.developer_ip_cidr != "" ? [1] : []
    content {
      default_action = "Deny"
      ip_rule {
        action   = "Allow"
        ip_range = var.developer_ip_cidr
      }
    }
  }
}

resource "azurerm_private_endpoint" "acr" {
  count               = var.container_registry_enabled ? 1 : 0
  name                = "${local.acr_name}-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pe.id
  tags                = var.tags

  private_service_connection {
    name                           = "${local.acr_name}-private-link-service-connection"
    private_connection_resource_id = azurerm_container_registry.main[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.acr_name}-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.main["privatelink.azurecr.io"].id]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = var.container_registry_enabled ? 1 : 0
  name                 = uuidv5("url", "${azurerm_container_registry.main[0].id}:${module.project.principal_id}:AcrPull")
  scope                = azurerm_container_registry.main[0].id
  role_definition_name = "AcrPull"
  principal_id         = module.project.principal_id
  principal_type       = "ServicePrincipal"
}