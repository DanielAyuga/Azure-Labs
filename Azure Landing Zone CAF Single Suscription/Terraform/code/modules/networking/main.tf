resource "azurerm_virtual_network" "vnet_hub" {
  name                = var.vnet_hub_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_hub_address]
}

resource "azurerm_subnet" "snet_bastion" {
  name                 = var.snet_bastion_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = [var.snet_bastion_address]
}