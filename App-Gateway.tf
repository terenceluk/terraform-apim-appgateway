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