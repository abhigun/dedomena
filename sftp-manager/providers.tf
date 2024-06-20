/**
  Copyright 2023 PhonePe Private Limited

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*/
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
   required_providers {
     azurerm = {
        source  = "hashicorp/azurerm"
       version = "=3.103.0"
      }
      azapi = {
        source = "Azure/azapi"
      }
   }
}

provider "azapi" {
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
