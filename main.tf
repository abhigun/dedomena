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
module "resource_group" {
  source   = "./modules/services/resource_group"
  name     = "${var.name}-rg"
  location = var.location
}

module "storage_account_sftp" {
  source                   = "./modules/services/storage_account"
  name                     = "demosftp"
  resource_group_name      = module.resource_group.resource-grp
  location                 = module.resource_group.resource-location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = true
  sftp_enabled             = true
}

module "local_user" {
  source = "./modules/services/storage_account_local_user"
  local_user = "demouser"
  resource_name = module.resource_group.resource-grp
  storage_account_id = module.storage_account_sftp.storage_account_id
}

