resource "azapi_resource" "foundry_account" {
  type      = "Microsoft.CognitiveServices/accounts@2026-05-01"
  name      = local.ai_services_name
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = local.ai_services_name
      disableLocalAuth       = false
      publicNetworkAccess    = "Disabled"
      networkAcls = {
        bypass              = "AzureServices"
        defaultAction       = "Deny"
        ipRules             = []
        virtualNetworkRules = []
      }
      networkInjections = var.network_injection_enabled ? [{
        scenario                   = "agent"
        subnetArmId                = azurerm_subnet.agents.id
        useMicrosoftManagedNetwork = false
      }] : null
    }
  }

  response_export_values = ["properties.endpoint", "identity.principalId"]
  depends_on             = [azurerm_cosmosdb_account.foundry, azurerm_search_service.foundry, azurerm_storage_account.foundry]

  # network-injected agent capability host provisioning can exceed the 30m default
  timeouts {
    create = "60m"
    update = "60m"
  }
}

resource "azapi_resource" "model_deployment" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2026-05-01"
  name      = var.model_name
  parent_id = azapi_resource.foundry_account.id

  body = {
    sku = {
      name     = var.model_sku_name
      capacity = var.model_capacity
    }
    properties = {
      model = {
        format  = var.model_format
        name    = var.model_name
        version = var.model_version
      }
    }
  }
}

module "project" {
  source = "./modules/foundry-project"

  account_id             = azapi_resource.foundry_account.id
  account_name           = local.ai_services_name
  location               = azurerm_resource_group.main.location
  project_name           = var.project_name
  project_description    = var.project_description
  project_display_name   = var.project_display_name
  capability_host_name   = var.project_capability_host_name
  ai_search_id           = azurerm_search_service.foundry.id
  ai_search_name         = azurerm_search_service.foundry.name
  ai_search_endpoint     = "https://${azurerm_search_service.foundry.name}.search.windows.net"
  ai_search_location     = azurerm_search_service.foundry.location
  cosmosdb_id            = azurerm_cosmosdb_account.foundry.id
  cosmosdb_name          = azurerm_cosmosdb_account.foundry.name
  cosmosdb_endpoint      = azurerm_cosmosdb_account.foundry.endpoint
  cosmosdb_location      = azurerm_cosmosdb_account.foundry.location
  storage_id             = azurerm_storage_account.foundry.id
  storage_name           = azurerm_storage_account.foundry.name
  storage_blob_endpoint  = azurerm_storage_account.foundry.primary_blob_endpoint
  storage_location       = azurerm_storage_account.foundry.location
  unique_connection_salt = ""

  # capability host connects to these over private link; wait for PEs + DNS records to exist first
  depends_on = [azurerm_private_endpoint.foundry]
}
