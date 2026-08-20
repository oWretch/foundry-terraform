locals {
  connection_suffix  = var.unique_connection_salt == "" ? "" : "-${var.project_name}"
  cosmos_connection  = "${var.cosmosdb_name}${local.connection_suffix}"
  storage_connection = "${var.storage_name}${local.connection_suffix}"
  search_connection  = "${var.ai_search_name}${local.connection_suffix}"
}

resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  name      = var.project_name
  parent_id = var.account_id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description = var.project_description
      displayName = var.project_display_name
    }
  }

  response_export_values = ["properties.internalId", "identity.principalId"]
}

resource "azapi_resource" "cosmos_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = local.cosmos_connection
  parent_id = azapi_resource.project.id
  body = {
    properties = {
      authType = "AAD"
      category = "CosmosDB"
      target   = var.cosmosdb_endpoint
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmosdb_id
        location   = var.cosmosdb_location
      }
    }
  }
}

resource "azapi_resource" "storage_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = local.storage_connection
  parent_id = azapi_resource.project.id
  body = {
    properties = {
      authType = "AAD"
      category = "AzureStorageAccount"
      target   = var.storage_blob_endpoint
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_id
        location   = var.storage_location
      }
    }
  }
}

resource "azapi_resource" "search_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = local.search_connection
  parent_id = azapi_resource.project.id
  body = {
    properties = {
      authType = "AAD"
      category = "CognitiveSearch"
      target   = var.ai_search_endpoint
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.ai_search_id
        location   = var.ai_search_location
      }
    }
  }
}