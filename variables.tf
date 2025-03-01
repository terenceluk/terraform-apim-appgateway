variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "key_vault_name" {
  description = "The name of the Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "The Azure AD tenant ID"
  type        = string
}

variable "service_principal_object_id" {
  description = "The object ID of the service principal"
  type        = string
}

variable "wildcard_certificate_path" {
  description = "The path to the wildcard certificate PFX file"
  type        = string
}

variable "wildcard_certificate_password" {
  description = "The password for the wildcard certificate PFX file"
  type        = string
}

variable "wildcard_certificate_name" {
  description = "The name for the wildcard certificate that is displayed in the portal"
  type        = string
}

variable "agw_identity_name" {
  description = "The name of the Application Gateway user-assigned managed identity"
  type        = string
}

variable "apim_name" {
  description = "The name of the API Management instance"
  type        = string
}

variable "publisher_email" {
  description = "The email address of the API Management publisher"
  type        = string
}

variable "publisher_name" {
  description = "The name of the API Management publisher"
  type        = string
}

variable "apim_sku_name" {
  description = "The SKU name for the API Management instance"
  type        = string
}

variable "apim_proxy_host_name" {
  description = "The host name for the API Management proxy"
  type        = string
}

variable "apim_management_host_name" {
  description = "The host name for the API Management management endpoint"
  type        = string
}

variable "apim_portal_host_name" {
  description = "The host name for the API Management developer portal"
  type        = string
}

variable "app_gateway_name" {
  description = "The name of the Application Gateway"
  type        = string
}

variable "app_gateway_private_ip_address" {
  description = "The private IP address for the Application Gateway"
  type        = string
}

variable "trusted_root_certificate_path" {
  description = "The path to the trusted root certificate CER file"
  type        = string
}

variable "waf_enabled" {
  description = "Whether Application Gateway WAF is enabled"
  type        = bool
  default     = true
}

variable "waf_firewall_mode" {
  description = "Whether WAF is in Prevention or Detection Mode"
  type        = string
}

variable "waf_rule_set_version" {
  description = "WAF ruleset version"
  type        = string
}

variable "nsg_agw_name" {
  description = "The name of the Application Gateway NSG"
  type        = string
}

variable "nsg_apim_name" {
  description = "The name of the API Management NSG"
  type        = string
}

variable "private_dns_zone_name" {
  description = "The name of the Private DNS Zone"
  type        = string
}

variable "api_record" {
  description = "The API A record name the Private DNS Zone"
  type        = string
}

variable "management_record" {
  description = "The Management A record name the Private DNS Zone"
  type        = string
}

variable "portal_record" {
  description = "The Developer Portal A record name the Private DNS Zone"
  type        = string
}

variable "virtual_network_link" {
  description = "The VNet link name for the Private DNS Zone"
  type        = string
}

variable "apim_private_ip" {
  description = "The private IP address for the API Management instance"
  type        = string
}

variable "app_gateway_public_ip_dns_label" {
  description = "The DNS label for the Application Gateway public IP"
  type        = string
}

variable "app_gateway_public_ip_name" {
  description = "The name of the Application Gateway public IP"
  type        = string
}

variable "apim_public_ip_dns_label" {
  description = "The DNS label for the API Management public IP"
  type        = string
}

variable "apim_public_ip_name" {
  description = "The name of the API Management public IP"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network"
  type        = string
}

variable "vnet_name" {
  description = "The name of the Virtual Network"
  type        = string
}

variable "apim_subnet_address_prefix" {
  description = "The address prefix for the API Management subnet"
  type        = string
}

variable "apim_subnet_name" {
  description = "The name of the API Management subnet"
  type        = string
}

variable "app_gateway_subnet_address_prefix" {
  description = "The address prefix for the Application Gateway subnet"
  type        = string
}

variable "app_gateway_subnet_name" {
  description = "The name of the Application Gateway subnet"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace for Application Gateway"
  type        = string
}

variable "log_analytics_workspace_name_apim" {
  description = "The name of the Log Analytics Workspace for API Management"
  type        = string
}
