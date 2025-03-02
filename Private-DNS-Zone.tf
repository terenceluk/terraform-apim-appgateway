# Private DNS Zone
# This resource creates a Private DNS Zone for internal name resolution.
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# Private DNS A Record for API
# This resource creates an A record in the Private DNS Zone for the API endpoint.
resource "azurerm_private_dns_a_record" "api_record" {
  name                = var.api_record
  records             = [var.apim_private_ip]
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  depends_on = [
    azurerm_private_dns_zone.private_dns_zone,
  ]
}

# Private DNS A Record for Management
# This resource creates an A record in the Private DNS Zone for the management endpoint.
resource "azurerm_private_dns_a_record" "management_record" {
  name                = var.management_record
  records             = [var.apim_private_ip]
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  depends_on = [
    azurerm_private_dns_zone.private_dns_zone,
  ]
}

# Private DNS A Record for Portal
# This resource creates an A record in the Private DNS Zone for the developer portal endpoint.
resource "azurerm_private_dns_a_record" "portal_record" {
  name                = var.portal_record
  records             = [var.apim_private_ip]
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  depends_on = [
    azurerm_private_dns_zone.private_dns_zone,
  ]
}

# Private DNS Zone Virtual Network Link
# This resource links the Private DNS Zone to the Virtual Network.
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = var.virtual_network_link
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  depends_on = [
    azurerm_private_dns_zone.private_dns_zone,
    azurerm_virtual_network.vnet,
  ]
}