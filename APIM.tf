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