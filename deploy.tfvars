# Resource Group Variables
# These variables define the location and name of the Azure Resource Group.
location            = "canadacentral"                 # The Azure region where resources will be deployed.
resource_group_name = "rg-cc-agw-apim-demo-terraform" # The name of the resource group.

# Key Vault Variables
# These variables define the Key Vault configuration and the tenant ID.
key_vault_name = "kv-contoso-dev-terraform"             # The name of the Azure Key Vault.
tenant_id      = "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx" # The Azure Active Directory tenant ID.

# Service Principal Variables
# These variables define the service principal object ID and certificate details. The purpose of this is so "resource "azurerm_key_vault_certificate" "wildcard_cert" can be used to import a PFX into the KeyVault with the user interactively running this TF code.
service_principal_object_id   = "54f69dce-9f86-4543-9ae8-4ebee1fc9fe4" # The Object ID of user account to assign assign Key Vault Certificates Officer RBAC permissions.
wildcard_certificate_path     = "c:/apim/wildcard.pfx"                 # The path to the wildcard certificate PFX file on the local computer running the TF code.
wildcard_certificate_password = "a"                                    # The password for the wildcard certificate PFX file.
wildcard_certificate_name     = "wildcard-certificate"

# Managed Identity Variables
# These variables define the name of the user-assigned managed identity for the Application Gateway.
agw_identity_name = "agw-user-identity" # The name of the user-assigned managed identity.

# API Management (APIM) Variables
# These variables define the APIM instance configuration.
apim_name                 = "apim-contoso-dev-terraform" # The name of the API Management instance.
publisher_email           = "terence.luk@contoso.com"      # The email address of the APIM publisher.
publisher_name            = "Contoso"                    # The name of the APIM publisher.
apim_sku_name             = "Developer_1"                # The SKU of the APIM instance.
apim_proxy_host_name      = "api.contoso.com"                 # The custom domain host name for the APIM gateway.
apim_management_host_name = "management.contoso.com"          # The custom domain host name for the APIM management endpoint.
apim_portal_host_name     = "portal.contoso.com"              # The custom domain host name for the APIM developer portal.
apim_private_ip           = "10.0.1.4"                   # The private IP address of the APIM instance.

# Application Gateway Variables
# These variables define the Application Gateway configuration.
app_gateway_name                = "agw-contoso-terraform"      # The name of the Application Gateway.
app_gateway_private_ip_address  = "10.0.0.100"                 # The private IP address of the Application Gateway.
app_gateway_public_ip_dns_label = "apim-contoso-dev-terraform" # The DNS label for the Application Gateway's public IP.
app_gateway_public_ip_name      = "pip-agw"                    # The name of the public IP for the Application Gateway.

# Network Security Group (NSG) Variables
# These variables define the NSG names for the Application Gateway and APIM.
nsg_agw_name  = "nsg-agw"  # The name of the NSG for the Application Gateway.
nsg_apim_name = "nsg-apim" # The name of the NSG for the APIM instance.

# Virtual Network (VNet) Variables
# These variables define the VNet and subnet configurations.
vnet_address_space                = "10.0.0.0/16"      # The address space for the Virtual Network.
vnet_name                         = "vnet-contoso"     # The name of the Virtual Network.
apim_subnet_address_prefix        = "10.0.1.0/24"      # The address prefix for the APIM subnet.
apim_subnet_name                  = "apimSubnet"       # The name of the APIM subnet.
app_gateway_subnet_address_prefix = "10.0.0.0/24"      # The address prefix for the Application Gateway subnet.
app_gateway_subnet_name           = "appGatewaySubnet" # The name of the Application Gateway subnet.

# Private DNS Zone Variables
# These variables define the Private DNS Zone configuration.
private_dns_zone_name = "contoso.com" # The name of the Private DNS Zone.
api_record            = "api"
management_record     = "management"
portal_record         = "portal"
virtual_network_link  = "mylink"

# Public IP Variables
# These variables define the public IP configurations for APIM and the Application Gateway.
apim_public_ip_dns_label = "apim-contoso-terraform" # The DNS label for the APIM public IP.
apim_public_ip_name      = "pip-apim"               # The name of the public IP for the APIM instance.

# Trusted Root Certificate Variables
# These variables define the path to the trusted root certificate.
trusted_root_certificate_path = "c:/apim/trustedroot.cer" # The path to the trusted root certificate file.

# WAF Variables
# These variables define the configuration of the WAF for the Application Gateway
waf_enabled          = true
waf_firewall_mode    = "Prevention" # or "Detection"
waf_rule_set_version = "3.2"        # 3.1, 3.0, 2.2.9, Microsoft_BotManagerRuleSet 0.1, Microsoft_BotManagerRuleSet 1.0, Microsoft_BotManagerRuleSet 2.1

# Log Analytics Workspace Variables
# These variables define the Log Analytics workspace names for monitoring.
log_analytics_workspace_name      = "lg-agw-demo"  # The name of the Log Analytics workspace for the Application Gateway.
log_analytics_workspace_name_apim = "lg-apim-demo" # The name of the Log Analytics workspace for APIM.
