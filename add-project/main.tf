data "azurerm_resource_group" "account" {
  name = var.account_resource_group_name
}

data "azurerm_search_service" "existing" {
  provider            = azurerm.search
  name                = var.existing_ai_search_name
  resource_group_name = var.search_resource_group_name
}

data "azurerm_storage_account" "existing" {
  provider            = azurerm.storage
  name                = var.existing_storage_name
  resource_group_name = var.storage_resource_group_name
}

data "azurerm_cosmosdb_account" "existing" {
  provider            = azurerm.cosmos
  name                = var.existing_cosmosdb_name
  resource_group_name = var.cosmosdb_resource_group_name
}

locals {
  final_project_name = lower("${var.project_name}${var.project_suffix}")
  account_id         = "${data.azurerm_resource_group.account.id}/providers/Microsoft.CognitiveServices/accounts/${var.existing_account_name}"
}

module "project" {
  source = "../modules/foundry-project"

  account_id             = local.account_id
  account_name           = var.existing_account_name
  location               = var.location
  project_name           = local.final_project_name
  project_description    = var.project_description
  project_display_name   = var.project_display_name
  capability_host_name   = var.capability_host_name
  ai_search_id           = data.azurerm_search_service.existing.id
  ai_search_name         = data.azurerm_search_service.existing.name
  ai_search_endpoint     = "https://${data.azurerm_search_service.existing.name}.search.windows.net"
  ai_search_location     = coalesce(var.ai_search_location, var.location)
  cosmosdb_id            = data.azurerm_cosmosdb_account.existing.id
  cosmosdb_name          = data.azurerm_cosmosdb_account.existing.name
  cosmosdb_endpoint      = data.azurerm_cosmosdb_account.existing.endpoint
  cosmosdb_location      = data.azurerm_cosmosdb_account.existing.location
  storage_id             = data.azurerm_storage_account.existing.id
  storage_name           = data.azurerm_storage_account.existing.name
  storage_blob_endpoint  = data.azurerm_storage_account.existing.primary_blob_endpoint
  storage_location       = data.azurerm_storage_account.existing.location
  unique_connection_salt = var.project_suffix
}