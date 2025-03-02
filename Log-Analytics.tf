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