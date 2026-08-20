resource "azurerm_public_ip" "firewall_data" {
  count               = var.firewall_enabled ? 1 : 0
  name                = "${var.prefix}-pip-azfw-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "firewall_management" {
  count               = var.firewall_enabled && var.firewall_sku_tier == "Basic" ? 1 : 0
  name                = "${var.prefix}-pip-azfw-mgmt-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "main" {
  count               = var.firewall_enabled ? 1 : 0
  name                = "${var.prefix}-afwp-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.firewall_sku_tier
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  count              = var.firewall_enabled ? 1 : 0
  name               = "DefaultRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 200

  application_rule_collection {
    name     = "AllowWebTraffic"
    priority = 100
    action   = "Allow"
    rule {
      name              = "AllowHttpHttps"
      source_addresses  = ["*"]
      destination_fqdns = ["*"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "AllowRFC1918"
    priority = 200
    action   = "Allow"
    dynamic "rule" {
      for_each = {
        "10to10"   = ["10.0.0.0/8", "10.0.0.0/8"]
        "10to172"  = ["10.0.0.0/8", "172.16.0.0/12"]
        "10to192"  = ["10.0.0.0/8", "192.168.0.0/16"]
        "172to10"  = ["172.16.0.0/12", "10.0.0.0/8"]
        "172to172" = ["172.16.0.0/12", "172.16.0.0/12"]
        "172to192" = ["172.16.0.0/12", "192.168.0.0/16"]
        "192to10"  = ["192.168.0.0/16", "10.0.0.0/8"]
        "192to172" = ["192.168.0.0/16", "172.16.0.0/12"]
        "192to192" = ["192.168.0.0/16", "192.168.0.0/16"]
      }
      content {
        name                  = "AllowRFC1918-${rule.key}"
        protocols             = ["Any"]
        source_addresses      = [rule.value[0]]
        destination_addresses = [rule.value[1]]
        destination_ports     = ["*"]
      }
    }
  }
}

resource "azurerm_firewall" "main" {
  count               = var.firewall_enabled ? 1 : 0
  name                = "${var.prefix}-azfw-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  tags                = var.tags

  ip_configuration {
    name                 = "${var.prefix}-azfw-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall_data[0].id
  }

  dynamic "management_ip_configuration" {
    for_each = var.firewall_sku_tier == "Basic" ? [1] : []
    content {
      name                 = "${var.prefix}-azfw-mgmt-ipconfig"
      subnet_id            = azurerm_subnet.hub["AzureFirewallManagementSubnet"].id
      public_ip_address_id = azurerm_public_ip.firewall_management[0].id
    }
  }

  depends_on = [azurerm_firewall_policy_rule_collection_group.main]
}

resource "azurerm_public_ip" "bastion" {
  count               = var.bastion_enabled ? 1 : 0
  name                = "${var.prefix}-pip-bastion-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "main" {
  count               = var.bastion_enabled ? 1 : 0
  name                = "${var.prefix}-bastion-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.bastion_sku
  tags                = var.tags

  ip_configuration {
    name                 = "bastionIpConfig"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

resource "azurerm_network_interface" "vm" {
  count               = var.vm_enabled ? 1 : 0
  name                = "${var.prefix}-nic-winvm-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "jumpbox" {
  count                 = var.vm_enabled ? 1 : 0
  name                  = "${var.prefix}-winvm1"
  computer_name         = "jumpbox1"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm[0].id]
  license_type          = "Windows_Server"
  patch_mode            = "AutomaticByPlatform"
  tags                  = var.tags

  os_disk {
    name                 = "${var.prefix}-osdisk-winvm-${local.suffix}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-hotpatch"
    version   = "latest"
  }

  boot_diagnostics {}
}