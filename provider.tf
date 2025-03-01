provider "azurerm" {
  features {
  }
  skip_provider_registration = true
  subscription_id            = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  environment                = "public"
  use_msi                    = false
  use_cli                    = true
  use_oidc                   = false
}
