resource "azurerm_private_dns_zone" "main" {
  for_each            = var.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each              = azurerm_private_dns_zone.main
  name                  = "${var.prefix}-hub-link-${local.suffix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aiapp" {
  for_each              = azurerm_private_dns_zone.main
  name                  = "${var.prefix}-aiapp-link-${local.suffix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.aiapp.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vm" {
  for_each              = azurerm_private_dns_zone.main
  name                  = "${var.prefix}-vm-link-${local.suffix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.vm.id
  registration_enabled  = false
  tags                  = var.tags
}