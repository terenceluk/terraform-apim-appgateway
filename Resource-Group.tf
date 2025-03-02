# Resource Group
# This resource creates an Azure Resource Group, which is a container for resources deployed in Azure.
resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.resource_group_name
}