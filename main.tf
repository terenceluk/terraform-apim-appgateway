# Resource Group
# This resource creates an Azure Resource Group, which is a container for resources deployed in Azure.
resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.resource_group_name
}

# Key Vault
# This resource creates an Azure Key Vault, that will store the wildcard certificate that is used for the API Management as well as the App Gateway.
resource "azurerm_key_vault" "kv" {
  enable_rbac_authorization = true
  location                  = var.location
  name                      = var.key_vault_name
  resource_group_name       = azurerm_resource_group.rg.name
  sku_name                  = "standard"
  tenant_id                 = var.tenant_id
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

# Add a delay to wait for RBAC permissions to propagate for assigning the user account's object ID (running this Terraform interactively via az login) that will be importing the PFX certificate into the Key Vault
# This resource introduces a delay to allow time for RBAC permissions to propagate across Azure.
resource "time_sleep" "wait_for_rbac_propagation" {
  create_duration = "2m" # Wait for 2 minutes (adjust as needed)
}

# Assign Key Vault Certificate Officer role to the service principal
# This resource assigns the "Key Vault Certificates Officer" role to the user account (running this Terraform interactively via az login) that will be importing the PFX certificate into the Key Vault.
resource "azurerm_role_assignment" "kv_cert_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = var.service_principal_object_id
}

# Import Wildcard Certificate into Key Vault
# This resource imports a wildcard certificate into the Key Vault using the user account running this Terraform interactively via az login.
resource "azurerm_key_vault_certificate" "wildcard_cert" {
  name         = var.wildcard_certificate_name
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = filebase64(var.wildcard_certificate_path)
    password = var.wildcard_certificate_password
  }

  depends_on = [
    azurerm_key_vault.kv,
    azurerm_role_assignment.kv_cert_officer,
    time_sleep.wait_for_rbac_propagation,
  ]
}

# Create a User-Assigned Managed Identity
# This resource creates a user-assigned managed identity that will be used for the App Gateway to access the certificate stored in the Key Vault (App Gateway doesn't have System Managed Identity).
resource "azurerm_user_assigned_identity" "agw_identity" {
  location            = azurerm_resource_group.rg.location
  name                = var.agw_identity_name
  resource_group_name = azurerm_resource_group.rg.name
}

# Assign RBAC Permissions to the User Managed Identity
# This resource assigns the "Key Vault Secrets User" role to the user-assigned managed identity that the App Gateway will use to access the certificate stored in the Key Vault.
resource "azurerm_role_assignment" "agw_identity_kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agw_identity.principal_id
}

# Add a delay to wait for RBAC permissions to propagate
# This resource introduces a delay to allow time for RBAC permissions to propagate after assigning roles to the user managed identity that the App Gateway will use
resource "time_sleep" "wait_for_rbac_propagation_after_identity_assignment" {
  create_duration = "2m"

  depends_on = [
    azurerm_role_assignment.agw_identity_kv_access,
  ]
}

# APIM
# This resource creates an Azure API Management (APIM) instance, which is used to publish, secure, and manage APIs.
resource "azurerm_api_management" "apim" {
  location             = var.location
  name                 = var.apim_name
  public_ip_address_id = azurerm_public_ip.apim_public_ip.id
  publisher_email      = var.publisher_email
  publisher_name       = var.publisher_name
  resource_group_name  = azurerm_resource_group.rg.name
  sku_name             = var.apim_sku_name
  virtual_network_type = "Internal"
  identity {
    type = "SystemAssigned"
  }
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_subnet.id
  }

  depends_on = [
    azurerm_public_ip.apim_public_ip,
    azurerm_subnet.apim_subnet,
    azurerm_subnet_network_security_group_association.apim_nsg_association,
  ]
}

# Assign RBAC Permissions to APIM's System-Assigned Identity
# This resource assigns the "Key Vault Secrets User" role to the APIM's system-assigned identity, allowing it to retrieve the wildcard certificate.
resource "azurerm_role_assignment" "apim_kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_api_management.apim.identity[0].principal_id
}

# Add a delay to wait for RBAC permissions to propagate
# This resource introduces a delay to allow time for RBAC permissions to propagate after assigning roles to the APIM's system-assigned identity.
resource "time_sleep" "wait_for_apim_role_propagation" {
  create_duration = "2m"

  depends_on = [
    azurerm_role_assignment.apim_kv_access,
  ]
}

# APIM Custom Domain Configuration
# This resource configures custom domains for the APIM gateway, management endpoint, and developer portal using the wildcard certificate from the Key Vault.
# This portion is split out to its own resource block as the managed identity needs to be granted to the Key Vault before these custom domains can be configured with the Key Vault certificate.
resource "azurerm_api_management_custom_domain" "apim_custom_domain" {
  api_management_id = azurerm_api_management.apim.id

  gateway {
    host_name                    = var.apim_proxy_host_name
    key_vault_id                 = azurerm_key_vault_certificate.wildcard_cert.secret_id
    negotiate_client_certificate = false
  }

  management {
    host_name                    = var.apim_management_host_name
    key_vault_id                 = azurerm_key_vault_certificate.wildcard_cert.secret_id
    negotiate_client_certificate = false
  }

  developer_portal {
    host_name                    = var.apim_portal_host_name
    key_vault_id                 = azurerm_key_vault_certificate.wildcard_cert.secret_id
    negotiate_client_certificate = false
  }

  depends_on = [
    azurerm_role_assignment.apim_kv_access,
    time_sleep.wait_for_apim_role_propagation,
  ]
}

# APIM Certificate Reference
# This resource references the wildcard certificate stored in the Key Vault for use in APIM.
resource "azurerm_api_management_certificate" "apim_cert" {
  name                = var.wildcard_certificate_name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  key_vault_secret_id = azurerm_key_vault_certificate.wildcard_cert.secret_id

  depends_on = [
    azurerm_key_vault_certificate.wildcard_cert,
    azurerm_api_management.apim,
    time_sleep.wait_for_apim_role_propagation, # Ensure role propagation is complete
  ]
}

# Application Gateway
# This resource creates an Azure Application Gateway, which publish the API Management's gateway, developer portal and management endpoint.
resource "azurerm_application_gateway" "app_gateway" {
  location            = var.location
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name

  # Add the User-Assigned Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agw_identity.id]
  }

  backend_address_pool {
    fqdns = [var.apim_proxy_host_name]
    name  = "gatewaybackend"
  }
  backend_address_pool {
    fqdns = [var.apim_management_host_name]
    name  = "managementbackend"
  }
  backend_address_pool {
    fqdns = [var.apim_portal_host_name]
    name  = "portalbackend"
  }

  backend_http_settings {
    cookie_based_affinity               = "Disabled"
    name                                = "apimPoolGatewaySetting"
    pick_host_name_from_backend_address = true
    port                                = 443
    probe_name                          = "apimgatewayprobe"
    protocol                            = "Https"
    request_timeout                     = 180
    trusted_root_certificate_names      = ["allowlistcert1"]
  }
  backend_http_settings {
    cookie_based_affinity               = "Disabled"
    name                                = "apimPoolManagementSetting"
    pick_host_name_from_backend_address = true
    port                                = 443
    probe_name                          = "apimmanagementprobe"
    protocol                            = "Https"
    request_timeout                     = 180
    trusted_root_certificate_names      = ["allowlistcert1"]
  }
  backend_http_settings {
    cookie_based_affinity               = "Disabled"
    name                                = "apimPoolPortalSetting"
    pick_host_name_from_backend_address = true
    port                                = 443
    probe_name                          = "apimportalprobe"
    protocol                            = "Https"
    request_timeout                     = 180
    trusted_root_certificate_names      = ["allowlistcert1"]
  }

  frontend_ip_configuration {
    name                 = "gateway-public-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }
  frontend_ip_configuration {
    name                          = "gateway-private-ip"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.app_gateway_private_ip_address
    subnet_id                     = azurerm_subnet.app_gateway_subnet.id
  }

  frontend_port {
    name = "port01"
    port = 443
  }

  gateway_ip_configuration {
    name      = "gatewayIP01"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }

  http_listener {
    frontend_ip_configuration_name = "gateway-private-ip"
    frontend_port_name             = "port01"
    host_name                      = var.apim_proxy_host_name
    name                           = "gatewaylistener-private"
    protocol                       = "Https"
    require_sni                    = true
    ssl_certificate_name           = var.wildcard_certificate_name
  }
  http_listener {
    frontend_ip_configuration_name = "gateway-private-ip"
    frontend_port_name             = "port01"
    host_name                      = var.apim_management_host_name
    name                           = "managementlistener-private"
    protocol                       = "Https"
    require_sni                    = true
    ssl_certificate_name           = var.wildcard_certificate_name
  }
  http_listener {
    frontend_ip_configuration_name = "gateway-private-ip"
    frontend_port_name             = "port01"
    host_name                      = var.apim_portal_host_name
    name                           = "portallistener-private"
    protocol                       = "Https"
    require_sni                    = true
    ssl_certificate_name           = var.wildcard_certificate_name
  }
  http_listener {
    frontend_ip_configuration_name = "gateway-public-ip"
    frontend_port_name             = "port01"
    host_name                      = var.apim_proxy_host_name
    name                           = "gatewaylistener"
    protocol                       = "Https"
    require_sni                    = true
    ssl_certificate_name           = var.wildcard_certificate_name
  }
  http_listener {
    frontend_ip_configuration_name = "gateway-public-ip"
    frontend_port_name             = "port01"
    host_name                      = var.apim_management_host_name
    name                           = "managementlistener"
    protocol                       = "Https"
    require_sni                    = true
    ssl_certificate_name           = var.wildcard_certificate_name
  }
  http_listener {
    frontend_ip_configuration_name = "gateway-public-ip"
    frontend_port_name             = "port01"
    host_name                      = var.apim_portal_host_name
    name                           = "portallistener"
    protocol                       = "Https"
    require_sni                    = true
    ssl_certificate_name           = var.wildcard_certificate_name
  }

  probe {
    host                = var.apim_proxy_host_name
    interval            = 30
    name                = "apimgatewayprobe"
    path                = "/status-0123456789abcdef"
    protocol            = "Https"
    timeout             = 120
    unhealthy_threshold = 8
    match {
      status_code = ["200-399"]
    }
  }
  probe {
    host                = var.apim_management_host_name
    interval            = 60
    name                = "apimmanagementprobe"
    path                = "/ServiceStatus"
    protocol            = "Https"
    timeout             = 300
    unhealthy_threshold = 8
    match {
      status_code = ["200-399"]
    }
  }
  probe {
    host                = var.apim_portal_host_name
    interval            = 60
    name                = "apimportalprobe"
    path                = "/signin"
    protocol            = "Https"
    timeout             = 300
    unhealthy_threshold = 8
    match {
      status_code = ["200-399"]
    }
  }

  request_routing_rule {
    backend_address_pool_name  = "gatewaybackend"
    backend_http_settings_name = "apimPoolGatewaySetting"
    http_listener_name         = "gatewaylistener"
    name                       = "gatewayrule"
    priority                   = 10
    rule_type                  = "Basic"
  }
  request_routing_rule {
    backend_address_pool_name  = "gatewaybackend"
    backend_http_settings_name = "apimPoolGatewaySetting"
    http_listener_name         = "gatewaylistener-private"
    name                       = "gatewayrule-private"
    priority                   = 11
    rule_type                  = "Basic"
  }
  request_routing_rule {
    backend_address_pool_name  = "managementbackend"
    backend_http_settings_name = "apimPoolManagementSetting"
    http_listener_name         = "managementlistener"
    name                       = "managementrule"
    priority                   = 30
    rule_type                  = "Basic"
  }
  request_routing_rule {
    backend_address_pool_name  = "managementbackend"
    backend_http_settings_name = "apimPoolManagementSetting"
    http_listener_name         = "managementlistener-private"
    name                       = "managementrule-private"
    priority                   = 31
    rule_type                  = "Basic"
  }
  request_routing_rule {
    backend_address_pool_name  = "portalbackend"
    backend_http_settings_name = "apimPoolPortalSetting"
    http_listener_name         = "portallistener"
    name                       = "portalrule"
    priority                   = 20
    rule_type                  = "Basic"
  }
  request_routing_rule {
    backend_address_pool_name  = "portalbackend"
    backend_http_settings_name = "apimPoolPortalSetting"
    http_listener_name         = "portallistener-private"
    name                       = "portalrule-private"
    priority                   = 21
    rule_type                  = "Basic"
  }

  sku {
    capacity = 2
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  ssl_certificate {
    name                = var.wildcard_certificate_name
    key_vault_secret_id = azurerm_key_vault_certificate.wildcard_cert.secret_id
  }

  # Trusted Root Certificates
  trusted_root_certificate {
    name = "allowlistcert1"
    data = filebase64(var.trusted_root_certificate_path)
  }

  # WAF configuration with rules disabled for Developer Portal. Ref article: learn.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway#expose-the-developer-portal-and-management-endpoint-externally-through-application-gateway
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_version = "3.2"
    disabled_rule_group {
      rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
      rules           = [942200, 942100, 942110, 942180, 942260, 942340, 942370, 942430, 942440]
    }
    disabled_rule_group {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
    }
    disabled_rule_group {
      rule_group_name = "REQUEST-931-APPLICATION-ATTACK-RFI"
    }
  }

  depends_on = [
    azurerm_public_ip.app_gateway_public_ip,
    azurerm_subnet.app_gateway_subnet,
    azurerm_key_vault_certificate.wildcard_cert,
    azurerm_user_assigned_identity.agw_identity,
    azurerm_role_assignment.agw_identity_kv_access,
    azurerm_subnet_network_security_group_association.app_gateway_nsg_association,
    time_sleep.wait_for_rbac_propagation_after_identity_assignment,
  ]
}

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

# Log Analytics Workspace
# This resource creates a Log Analytics workspace for App Gateway monitoring and logging.
resource "azurerm_log_analytics_workspace" "log_analytics_workspace_app_gateway" {
  location            = var.location
  name                = var.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,

  ]
}

# Log Analytics Workspace for APIM
# This resource creates a Log Analytics workspace specifically for APIM monitoring.
resource "azurerm_log_analytics_workspace" "log_analytics_workspace_apim" {
  location            = var.location
  name                = var.log_analytics_workspace_name_apim
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,

  ]
}

# Log Analytics Workspace diagnostics settings for APIM
# This resource configures the logging for APIM
resource "azurerm_monitor_diagnostic_setting" "apim_diagnostic" {
  name                       = "apim-diagnostic-settings"
  target_resource_id         = azurerm_api_management.apim.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace_apim.id

  # Enable all logs
  enabled_log {
    category_group = "allLogs"
  }
  enabled_log {
    category_group = "audit"
  }
  # Enable all metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_log_analytics_workspace.log_analytics_workspace_apim,
    azurerm_api_management.apim,
  ]
}

# Log Analytics Workspace diagnostics settings for App Gateway
# This resource configures the logging for App Gateway
resource "azurerm_monitor_diagnostic_setting" "app_gateway_diagnostic" {
  name                       = "appgw-diagnostic-settings"
  target_resource_id         = azurerm_application_gateway.app_gateway.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace_app_gateway.id

  # Enable all logs
  enabled_log {
    category_group = "allLogs"
  }

  # Enable all metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_log_analytics_workspace.log_analytics_workspace_app_gateway,
    azurerm_application_gateway.app_gateway,
  ]
}
