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
  first_party_users = local.details.first_party_users
  partner_users = local.details.partner_users
}

# Loop through first party users
module "first_party_sftp_users" {
  source = "../modules/services/storage_account_local_user"
  for_each = { for user in local.first_party_users : user => user }

  local_user = each.key
  resource_name = module.first_party_container.storage_container_name
  storage_account_id = module.storage_account_sftp.storage_account_id
}

# Loop through partner users
module "partner_sftp_users" {
  source = "../modules/services/storage_account_local_user"
  for_each = { for user in local.partner_users : user => user }

  local_user = each.key
  resource_name = module.partner_container.storage_container_name
  storage_account_id = module.storage_account_sftp.storage_account_id
}

# Generate passwords for first party users
resource "azapi_resource_action" "first_party_passwords" {
  for_each = { for user in local.first_party_users : user => user }

  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.first_party_sftp_users[each.key].id
  action = "regeneratePassword"
  body = jsonencode({
    username = each.key
  })

  response_export_values = ["sshPassword"]
}

# Generate passwords for partner users
resource "azapi_resource_action" "partner_passwords" {
  for_each = { for user in local.partner_users : user => user }

  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.partner_sftp_users[each.key].id
  action = "regeneratePassword"
  body = jsonencode({
    username = each.key
  })

  response_export_values = ["sshPassword"]
}


# module "first_party_sftp_users" {
#   source = "../modules/services/storage_account_local_user"
#   local_user = local.input.first_party_details.local_user_name
#   resource_name = module.first_party_container.storage_container_name
#   storage_account_id = module.storage_account_sftp.storage_account_id
# }

# module "partner_sftp_users" {
#   source = "../modules/services/storage_account_local_user"
#   local_user = local.input.partner_details.local_user_name
#   resource_name = module.partner_container.storage_container_name
#   storage_account_id = module.storage_account_sftp.storage_account_id
# }

# resource "azapi_resource_action" "first_party_passwords" {
#   type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
#   resource_id = module.first_party_local_user.id
#   action = "regeneratePassword"
#   body = jsonencode({
#   username = local.input.first_party_details.local_user_name
#   })

#   response_export_values = ["sshPassword"]
# }

# resource "azapi_resource_action" "partner_password" {
#   type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
#   resource_id = module.partner_local_user.id
#   action = "regeneratePassword"
#   body = jsonencode({
#   username = local.input.partner_details.local_user_name
#   })

#   response_export_values = ["sshPassword"]
# }



