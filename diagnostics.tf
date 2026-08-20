resource "azurerm_log_analytics_workspace" "main" {
  name                       = "${var.prefix}-law-${local.suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  sku                        = "PerGB2018"
  retention_in_days          = var.diagnostic_retention_days
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  tags                       = var.tags
}

resource "azurerm_storage_account" "diagnostics" {
  name                            = substr(lower(replace("${var.prefix}diag${local.suffix}", "-", "")), 0, 24)
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = var.tags
}

locals {
  diagnostic_targets = merge(
    {
      hub_vnet   = { id = azurerm_virtual_network.hub.id, skip_logs = false }
      vm_vnet    = { id = azurerm_virtual_network.vm.id, skip_logs = false }
      aiapp_vnet = { id = azurerm_virtual_network.aiapp.id, skip_logs = false }
      search     = { id = azurerm_search_service.foundry.id, skip_logs = false }
      cosmosdb   = { id = azurerm_cosmosdb_account.foundry.id, skip_logs = false }
      storage    = { id = azurerm_storage_account.foundry.id, skip_logs = true }
      ai_account = { id = azapi_resource.foundry_account.id, skip_logs = false }
    },
    var.firewall_enabled ? {
      firewall     = { id = azurerm_firewall.main[0].id, skip_logs = false }
      firewall_pip = { id = azurerm_public_ip.firewall_data[0].id, skip_logs = false }
    } : {},
    var.bastion_enabled ? {
      bastion     = { id = azurerm_bastion_host.main[0].id, skip_logs = false }
      bastion_pip = { id = azurerm_public_ip.bastion[0].id, skip_logs = false }
    } : {}
  )
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each                   = local.diagnostic_targets
  name                       = "${each.key}-diag"
  target_resource_id         = each.value.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  storage_account_id         = azurerm_storage_account.diagnostics.id

  dynamic "enabled_log" {
    for_each = each.value.skip_logs ? [] : [1]
    content {
      category_group = "allLogs"
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}