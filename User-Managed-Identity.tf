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