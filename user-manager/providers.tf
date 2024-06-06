terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
   required_providers {
     azurerm = {
        source  = "hashicorp/azurerm"
       version = "=3.96.0"
      }
   }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }

}

provider "azuread" {

}
