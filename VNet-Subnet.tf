# VNet and Subnet for APIM and App Gateway
# This resource creates a Virtual Network (VNet) for the APIM and Application Gateway resources.
resource "azurerm_virtual_network" "vnet" {
  address_space       = [var.vnet_address_space]
  location            = var.location
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# Subnet for APIM
# This resource creates a subnet within the VNet for the APIM instance.
resource "azurerm_subnet" "apim_subnet" {
  address_prefixes     = [var.apim_subnet_address_prefix]
  name                 = var.apim_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}

# Subnet for App Gateway
# This resource creates a subnet within the VNet for the Application Gateway.
resource "azurerm_subnet" "app_gateway_subnet" {
  address_prefixes     = [var.app_gateway_subnet_address_prefix]
  name                 = var.app_gateway_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}