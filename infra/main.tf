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

locals {
  input = yamldecode(file("${path.module}/values.yaml"))
}

module "resource_group" {
  source   = "../modules/services/resource_group"
  name     = "${var.name}-rg"
  location = var.location
}


module "az_kv" {
  source         = "../modules/services/key_vault"
  name           = "azusers"
  location       = module.resource_group.resource-location
  resource_group = module.resource_group.resource-grp
}



module "storage_account_first_party" {
  source                   = "../modules/services/storage_account"
  name                     = local.input.first_party_details.storage_account_name
  resource_group_name      = module.resource_group.resource-grp
  location                 = module.resource_group.resource-location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = true
  sftp_enabled             = true
}

# Workaround until azurerm_storage_account supports isSftpEnabled property
# see https://github.com/hashicorp/terraform-provider-azurerm/issues/14736
resource "azapi_update_resource" "enable_sftp" {
  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = module.storage_account_first_party.storage_account_id

  body = jsonencode({
    properties = {
      isSftpEnabled = false
    }
  })
}

module "storage_account_partner" {
  source                   = "../modules/services/storage_account"
  name                     = local.input.partner_details.storage_account_name
  resource_group_name      = module.resource_group.resource-grp
  location                 = module.resource_group.resource-location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = true
  sftp_enabled             = true
}

# Workaround until azurerm_storage_account supports isSftpEnabled property
# see https://github.com/hashicorp/terraform-provider-azurerm/issues/14736
resource "azapi_update_resource" "enable_sftp" {
  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = module.storage_account_partner.storage_account_id

  body = jsonencode({
    properties = {
      isSftpEnabled = false
    }
  })
}

module "first_party_container" {
 source                = "../modules/services/storage_container"
 name                  = local.input.first_party_details.storage_container_name
 storage_account_name  = module.storage_account_first_party.storage_account
 container_access_type = "blob"
}

module "partner_container" {
 source                = "../modules/services/storage_container"
 name                  = local.input.partner_details.storage_container_name
 storage_account_name  = module.storage_account_partner.storage_account
 container_access_type = "blob"
}


module "synapse_spark" {
  source                           = "../modules/services/synapse_spark_pool"
  name                             = var.name
  resource_group_name              = module.resource_group.resource-grp
  location                         = module.resource_group.resource-location
  sql_administrator_login          = yamldecode(file("${path.module}/values.yaml")).sql_administrator_login
  key_vault_id                     = module.az_kv.key_vault_id
  storage_account_name             = var.synapse_storage_account
}
