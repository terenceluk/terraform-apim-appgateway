# Public IP Address for App Gateway
# This resource creates a public IP address for the Application Gateway.
resource "azurerm_public_ip" "app_gateway_public_ip" {
  allocation_method   = "Static"
  domain_name_label   = var.app_gateway_public_ip_dns_label
  location            = var.location
  name                = var.app_gateway_public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# Public IP Address for APIM
# This resource creates a public IP address for the API Management instance.
resource "azurerm_public_ip" "apim_public_ip" {
  allocation_method   = "Static"
  domain_name_label   = var.apim_public_ip_dns_label
  location            = var.location
  name                = var.apim_public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}