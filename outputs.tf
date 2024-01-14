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
output "values" {
  value = module.ad_users
}

output "users_keyvault" {
  value = module.az_kv.key_vault
}

output "user_object_ids" {
  value = [for user in local.user_list : user.user_object_id]
}

output "sftp_storage_account" {
  value = module.storage_account_sftp.storage_account
}

output "resource_group_name" {
  value = module.resource_group.resource-grp
}