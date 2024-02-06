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
  details = yamldecode(file("${path.module}/values.yaml"))
}

module "storage_container" {
  source                = "../modules/services/storage_container"
  name                  = local.details.container_name
  storage_account_name  = local.details.storage_account_name
  container_access_type = "blob"
}

module "local_user" {
  source = "../modules/services/storage_account_local_user"
  local_user = local.details.local_user_name
  resource_name = module.storage_container.storage_container_name
  storage_account_id = local.details.storage_account_id
}

# Workaround until azurerm_storage_account supports isSftpEnabled property
# see https://github.com/hashicorp/terraform-provider-azurerm/issues/14736
resource "azapi_update_resource" "enable_sftp" {
  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = local.details.storage_account_id

  body = jsonencode({
    properties = {
      isSftpEnabled = true
    }
  })
}

resource "azapi_resource_action" "sftpPassword" {
  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.local_user.id
  action = "regeneratePassword"
  body = jsonencode({
  username = local.details.local_user_name
  })

  response_export_values = ["sshPassword"]
}


