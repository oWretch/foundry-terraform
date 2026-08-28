resource "azurerm_cosmosdb_account" "foundry" {
  name                          = local.cosmosdb_name
  location                      = contains(["eastus2euap", "centraluseuap"], var.location) ? "westus" : var.location
  resource_group_name           = azurerm_resource_group.main.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  local_authentication_enabled  = false
  public_network_access_enabled = false
  tags                          = var.tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_search_service" "foundry" {
  name                          = local.ai_search_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  sku                           = "standard"
  replica_count                 = 1
  partition_count               = 1
  public_network_access_enabled = false
  local_authentication_enabled  = true
  authentication_failure_mode   = "http401WithBearerChallenge"
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "foundry" {
  name                            = local.storage_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = contains(["southindia", "westus"], var.location) ? "GRS" : "ZRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  tags                            = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
