# NSG for Application Gateway
# This resource creates a Network Security Group (NSG) for the Application Gateway.
resource "azurerm_network_security_group" "app_gateway_nsg" {
  location            = var.location
  name                = var.nsg_agw_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# NSG Rule for AppGw inbound
# This rule allows inbound traffic to the Application Gateway from the GatewayManager service.
resource "azurerm_network_security_rule" "app_gateway_inbound" {
  access                      = "Allow"
  description                 = "AppGw inbound"
  destination_address_prefix  = "*"
  destination_port_range      = "65200-65535"
  direction                   = "Inbound"
  name                        = "appgw-in"
  network_security_group_name = azurerm_network_security_group.app_gateway_nsg.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  source_address_prefix       = "GatewayManager"
  source_port_range           = "*"

  depends_on = [
    azurerm_network_security_group.app_gateway_nsg,
  ]
}

# NSG Rule for AppGw inbound Internet
# This rule allows inbound HTTPS traffic from the Internet to the Application Gateway.
resource "azurerm_network_security_rule" "app_gateway_inbound_internet" {
  access      = "Allow"
  description = "AppGw inbound Internet"
  destination_address_prefixes = [
    var.app_gateway_private_ip_address,
    azurerm_public_ip.app_gateway_public_ip.ip_address,
  ]
  destination_port_range      = "443"
  direction                   = "Inbound"
  name                        = "appgw-in-internet"
  network_security_group_name = azurerm_network_security_group.app_gateway_nsg.name
  priority                    = 110
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg.name
  source_address_prefix       = "Internet"
  source_port_range           = "*"

  depends_on = [
    azurerm_network_security_group.app_gateway_nsg,
    azurerm_public_ip.app_gateway_public_ip,
  ]
}

# NSG for APIM
# This resource creates a Network Security Group (NSG) for the API Management (APIM) instance.
resource "azurerm_network_security_group" "apim_nsg" {
  location            = var.location
  name                = var.nsg_apim_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# NSG Rule for APIM inbound
# This rule allows inbound traffic to the APIM instance from the ApiManagement service.
resource "azurerm_network_security_rule" "apim_inbound" {
  access                      = "Allow"
  description                 = "APIM inbound"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "3443"
  direction                   = "Inbound"
  name                        = "APIM-Management"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg.name
  source_address_prefix       = "ApiManagement"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.apim_nsg,
  ]
}

# NSG Rule for App Gateway to APIM
# This rule allows inbound traffic from the Application Gateway subnet to the APIM subnet.
resource "azurerm_network_security_rule" "allow_app_gateway_to_apim" {
  access                      = "Allow"
  description                 = "Allows inbound App Gateway traffic to APIM"
  destination_address_prefix  = var.apim_subnet_address_prefix
  destination_port_range      = "443"
  direction                   = "Inbound"
  name                        = "AllowAppGatewayToAPIM"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  priority                    = 110
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg.name
  source_address_prefix       = var.app_gateway_subnet_address_prefix
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.apim_nsg,
  ]
}

# NSG Rule for Azure Load Balancer to APIM
# This rule allows inbound traffic from the Azure Load Balancer to the APIM instance.
resource "azurerm_network_security_rule" "allow_azure_load_balancer" {
  access                      = "Allow"
  description                 = "Allows inbound Azure Infrastructure Load Balancer traffic to APIM"
  destination_address_prefix  = var.apim_subnet_address_prefix
  destination_port_range      = "6390"
  direction                   = "Inbound"
  name                        = "AllowAzureLoadBalancer"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  priority                    = 120
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg.name
  source_address_prefix       = "AzureLoadBalancer"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.apim_nsg,
  ]
}

# NSG Rule for APIM to Key Vault
# This rule allows outbound traffic from the APIM subnet to Azure Key Vault.
resource "azurerm_network_security_rule" "allow_apim_to_key_vault" {
  access                      = "Allow"
  description                 = "Allows outbound traffic to Azure Key Vault"
  destination_address_prefix  = "AzureKeyVault"
  destination_port_range      = "443"
  direction                   = "Outbound"
  name                        = "AllowKeyVault"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg.name
  source_address_prefix       = var.apim_subnet_address_prefix
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.apim_nsg,
  ]
}

# Subnet NSG Association for APIM
# This resource associates the NSG with the APIM subnet.
resource "azurerm_subnet_network_security_group_association" "apim_nsg_association" {
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
  subnet_id                 = azurerm_subnet.apim_subnet.id
  depends_on = [
    azurerm_network_security_group.apim_nsg,
    azurerm_subnet.apim_subnet,
  ]
}

# Subnet NSG Association for App Gateway
# This resource associates the NSG with the Application Gateway subnet.
resource "azurerm_subnet_network_security_group_association" "app_gateway_nsg_association" {
  network_security_group_id = azurerm_network_security_group.app_gateway_nsg.id
  subnet_id                 = azurerm_subnet.app_gateway_subnet.id
  depends_on = [
    azurerm_network_security_group.app_gateway_nsg,
    azurerm_subnet.app_gateway_subnet,
  ]
}