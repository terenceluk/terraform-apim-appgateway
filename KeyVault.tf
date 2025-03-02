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
