locals {
  private_endpoints = {
    ai_account = {
      name        = "${local.ai_services_name}-private-endpoint"
      resource_id = azapi_resource.foundry_account.id
      subresource = "account"
      dns_zones = [
        "privatelink.services.ai.azure.com",
        "privatelink.openai.azure.com",
        "privatelink.cognitiveservices.azure.com"
      ]
    }
    search = {
      name        = "${local.ai_search_name}-private-endpoint"
      resource_id = azurerm_search_service.foundry.id
      subresource = "searchService"
      dns_zones   = ["privatelink.search.windows.net"]
    }
    storage = {
      name        = "${local.storage_name}-private-endpoint"
      resource_id = azurerm_storage_account.foundry.id
      subresource = "blob"
      dns_zones   = ["privatelink.blob.core.windows.net"]
    }
    cosmosdb = {
      name        = "${local.cosmosdb_name}-private-endpoint"
      resource_id = azurerm_cosmosdb_account.foundry.id
      subresource = "Sql"
      dns_zones   = ["privatelink.documents.azure.com"]
    }
  }
}

resource "azurerm_private_endpoint" "foundry" {
  for_each            = local.private_endpoints
  name                = each.value.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pe.id
  tags                = var.tags

  private_service_connection {
    name                           = "${each.value.name}-link-service-connection"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${each.value.name}-dns-group"
    private_dns_zone_ids = [for zone in each.value.dns_zones : azurerm_private_dns_zone.main[zone].id]
  }
}