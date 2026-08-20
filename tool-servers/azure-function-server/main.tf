data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_subnet" "integration" {
  name                 = var.integration_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  address_prefixes     = [var.integration_subnet_prefix]

  delegation {
    name = "Microsoft.Web.serverFarms"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_storage_account" "function" {
  name                            = "${substr(var.base_name, 0, 20)}stor"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = var.tags

  network_rules {
    default_action = "Allow"
  }
}

resource "azurerm_service_plan" "function" {
  name                = "${var.base_name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "EP1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "function" {
  name                          = "${var.base_name}-func"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.function.id
  storage_account_name          = azurerm_storage_account.function.name
  storage_account_access_key    = azurerm_storage_account.function.primary_access_key
  virtual_network_subnet_id     = azurerm_subnet.integration.id
  public_network_access_enabled = true
  https_only                    = true
  functions_extension_version   = "~4"
  tags                          = var.tags

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    WEBSITE_CONTENTOVERVNET  = "1"
    WEBSITE_VNET_ROUTE_ALL   = "1"
  }

  site_config {
    vnet_route_all_enabled = true
    application_stack {
      python_version = "3.11"
    }
  }
}

locals {
  private_endpoints = {
    function = {
      name        = "${var.base_name}-func-pe"
      resource_id = azurerm_linux_function_app.function.id
      subresource = "sites"
      dns_zone    = "privatelink.azurewebsites.net"
    }
    blob = {
      name        = "${var.base_name}-blob-pe"
      resource_id = azurerm_storage_account.function.id
      subresource = "blob"
      dns_zone    = "privatelink.blob.core.windows.net"
    }
    queue = {
      name        = "${var.base_name}-queue-pe"
      resource_id = azurerm_storage_account.function.id
      subresource = "queue"
      dns_zone    = "privatelink.queue.core.windows.net"
    }
    file = {
      name        = "${var.base_name}-file-pe"
      resource_id = azurerm_storage_account.function.id
      subresource = "file"
      dns_zone    = "privatelink.file.core.windows.net"
    }
  }
}

resource "azurerm_private_dns_zone" "main" {
  for_each            = toset([for endpoint in local.private_endpoints : endpoint.dns_zone])
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = azurerm_private_dns_zone.main
  name                  = "${var.vnet_name}-${replace(each.key, ".", "-")}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "main" {
  for_each            = local.private_endpoints
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = data.azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = each.value.subresource
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.main[each.value.dns_zone].id]
  }
}