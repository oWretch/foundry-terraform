locals {
  principal_id           = azapi_resource.project.output.identity.principalId
  workspace_id           = azapi_resource.project.output.properties.internalId
  workspace_guid         = "${substr(local.workspace_id, 0, 8)}-${substr(local.workspace_id, 8, 4)}-${substr(local.workspace_id, 12, 4)}-${substr(local.workspace_id, 16, 4)}-${substr(local.workspace_id, 20, 12)}"
  role_salt              = var.unique_connection_salt
  storage_abac_condition = "((!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/read'})  AND  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/filter/action'}) AND  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write'}) ) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase '${local.workspace_guid}' AND @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-azureml-agent'))"
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  name               = uuidv5("url", "${local.principal_id}:${var.ai_search_id}:8ebe5a00-799e-43f5-93ac-243d3dce84a7:${local.role_salt}")
  scope              = var.ai_search_id
  role_definition_id = "/subscriptions/${split("/", var.ai_search_id)[2]}/providers/Microsoft.Authorization/roleDefinitions/8ebe5a00-799e-43f5-93ac-243d3dce84a7"
  principal_id       = local.principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "search_service_contributor" {
  name               = uuidv5("url", "${local.principal_id}:${var.ai_search_id}:7ca78c08-252a-4471-8644-bb5ff32d4ba0:${local.role_salt}")
  scope              = var.ai_search_id
  role_definition_id = "/subscriptions/${split("/", var.ai_search_id)[2]}/providers/Microsoft.Authorization/roleDefinitions/7ca78c08-252a-4471-8644-bb5ff32d4ba0"
  principal_id       = local.principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  name               = uuidv5("url", "${local.principal_id}:${var.storage_id}:ba92f5b4-2d11-453d-a403-e96b0029c9fe:${local.role_salt}")
  scope              = var.storage_id
  role_definition_id = "/subscriptions/${split("/", var.storage_id)[2]}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
  principal_id       = local.principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cosmosdb_operator" {
  name               = uuidv5("url", "${local.principal_id}:${var.cosmosdb_id}:230815da-be43-4aae-9cb4-875f7bd000aa:${local.role_salt}")
  scope              = var.cosmosdb_id
  role_definition_id = "/subscriptions/${split("/", var.cosmosdb_id)[2]}/providers/Microsoft.Authorization/roleDefinitions/230815da-be43-4aae-9cb4-875f7bd000aa"
  principal_id       = local.principal_id
  principal_type     = "ServicePrincipal"
}

resource "azapi_resource" "capability_host" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2026-05-01"
  name                      = var.capability_host_name
  parent_id                 = azapi_resource.project.id
  schema_validation_enabled = false
  body = {
    properties = {
      capabilityHostKind       = "Agents"
      storageConnections       = [local.storage_connection]
      threadStorageConnections = [local.cosmos_connection]
      vectorStoreConnections   = [local.search_connection]
    }
  }

  depends_on = [
    azapi_resource.cosmos_connection,
    azapi_resource.storage_connection,
    azapi_resource.search_connection,
    azurerm_role_assignment.search_index_data_contributor,
    azurerm_role_assignment.search_service_contributor,
    azurerm_role_assignment.storage_blob_data_contributor,
    azurerm_role_assignment.cosmosdb_operator
  ]
}

resource "azurerm_role_assignment" "storage_blob_data_owner" {
  name               = uuidv5("url", "${local.principal_id}:${var.storage_id}:b7e6dc6d-f1e8-4753-8033-0f276bb0955b:${local.role_salt}")
  scope              = var.storage_id
  role_definition_id = "/subscriptions/${split("/", var.storage_id)[2]}/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b"
  principal_id       = local.principal_id
  principal_type     = "ServicePrincipal"
  condition_version  = "2.0"
  condition          = local.storage_abac_condition
  depends_on         = [azapi_resource.capability_host]
}

resource "azapi_resource" "cosmos_data_plane_assignment" {
  type      = "Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15"
  name      = uuidv5("url", "${local.workspace_guid}:${var.cosmosdb_id}:00000000-0000-0000-0000-000000000002:${local.principal_id}:${local.role_salt}")
  parent_id = var.cosmosdb_id
  body = {
    properties = {
      principalId      = local.principal_id
      roleDefinitionId = "${var.cosmosdb_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
      scope            = var.cosmosdb_id
    }
  }
  depends_on = [azapi_resource.capability_host]
}
