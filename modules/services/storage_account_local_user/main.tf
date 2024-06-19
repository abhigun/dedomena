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

resource "azurerm_storage_account_local_user" "local_user" {
  name                 = var.local_user
  storage_account_id   = var.storage_account_id
  ssh_key_enabled      = false
  ssh_password_enabled = true
  dynamic "permission_scope" {
    for_each = var.containers
    content {
      permissions {
        read   = true
        create = contains(["rw", "rwd"], permission_scope.value.user_access) ? true : false
        write  = contains(["rw", "rwd"], permission_scope.value.user_access) ? true : false
        delete = permission_scope.value.user_access == "rwd" ? true : false
        list   = true
      }
      service       = "blob"
      resource_name = permission_scope.value.container_name
    }
  }
}
