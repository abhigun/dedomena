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
resource "random_id" "saname" {
  byte_length = 5
  prefix = var.name
}

resource "azurerm_storage_account" "storage_account" {
  name                     = random_id.saname.hex
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

#  sftp_enabled = var.sftp_enabled
  is_hns_enabled = var.is_hns_enabled

  tags = {
    Name = var.name
  }
}
