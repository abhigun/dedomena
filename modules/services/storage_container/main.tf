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
resource "azurerm_storage_container" "storage_container" {
  name                  = var.name
  storage_account_name  = var.storage_account_name
  container_access_type = var.container_access_type
}

resource "azurerm_storage_management_policy" "policy" {
  count              = var.enable_ttl ? 1 : 0
  storage_account_id = var.storage_account_id

  rule {
    name    = "${var.name}-delete-data"
    enabled = true
    filters {
      prefix_match = ["${var.name}/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than          = var.ttl_days
      }
    }
  }
}
