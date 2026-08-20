resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-vnet-hub-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.hub_vnet_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  for_each             = local.hub_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

resource "azurerm_virtual_network" "vm" {
  name                = "${var.prefix}-vnet-vm-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vm_vnet_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "vm" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vm.name
  address_prefixes     = [local.vm_subnet_prefix]
}

resource "azurerm_virtual_network" "aiapp" {
  name                = "${var.prefix}-vnet-aiapp-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.aiapp_vnet_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "pe" {
  name                 = "pe"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.aiapp.name
  address_prefixes     = [local.pe_subnet_prefix]
}

resource "azurerm_subnet" "agents" {
  name                 = "agents"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.aiapp.name
  address_prefixes     = [local.agents_subnet_prefix]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}

resource "azurerm_subnet" "mcp" {
  name                 = "mcp"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.aiapp.name
  address_prefixes     = [local.mcp_subnet_prefix]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}

resource "azurerm_virtual_network_peering" "hub_to_vm" {
  name                      = "${var.prefix}-hub-to-vm"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.vm.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "vm_to_hub" {
  name                      = "${var.prefix}-vm-to-hub"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vm.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "hub_to_aiapp" {
  name                      = "${var.prefix}-hub-to-aiapp"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.aiapp.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "aiapp_to_hub" {
  name                      = "${var.prefix}-aiapp-to-hub"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.aiapp.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

resource "azurerm_route_table" "spokes" {
  count               = var.firewall_enabled ? 1 : 0
  name                = "${var.prefix}-rt-spokes-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.main[0].ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "vm" {
  count          = var.firewall_enabled ? 1 : 0
  subnet_id      = azurerm_subnet.vm.id
  route_table_id = azurerm_route_table.spokes[0].id
}

resource "azurerm_subnet_route_table_association" "pe" {
  count          = var.firewall_enabled ? 1 : 0
  subnet_id      = azurerm_subnet.pe.id
  route_table_id = azurerm_route_table.spokes[0].id
}