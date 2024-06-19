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
  first_party_details = local.details.first_party_details
  first_party_users = local.first_party_details.users
  partner_details = local.details.partner_details
  partner_users = local.partner_details.users
}

# Loop through first party users
module "first_party_private_sftp_users" {
  source = "../modules/services/storage_account_local_user"
  for_each = { for user in local.first_party_users : user => user }
  storage_account_id = local.first_party_details.account_id
  local_user = each.key
  containers = [
    {
      container_name = local.first_party_details.private_container_name
      user_access    = "rwd"
    },
    {
      container_name = local.first_party_details.public_container_name
      user_access    = "rwd"
    }
  ]
}

# Loop through partner users
module "partner_sftp_private_users" {
  source = "../modules/services/storage_account_local_user"
  for_each = { for user in local.partner_users : user => user }
  storage_account_id = local.partner_details.account_id
  local_user = each.key
  containers = [
    {
      container_name = local.partner_details.private_container_name
      user_access    = "rwd"
    },
    {
      container_name = local.partner_details.public_container_name
      user_access    = "rwd"
    }
  ]
}

# Generate passwords for first party users
resource "azapi_resource_action" "first_party_private_passwords" {
  for_each = { for user in local.first_party_users : user => user }

  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.first_party_private_sftp_users[each.key].id
  action = "regeneratePassword"
  body = jsonencode({
    username = each.key
  })

  response_export_values = ["sshPassword"]
}

# Generate passwords for partner users
resource "azapi_resource_action" "partner_private_passwords" {
  for_each = { for user in local.partner_users : user => user }

  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.partner_sftp_private_users[each.key].id
  action = "regeneratePassword"
  body = jsonencode({
    username = each.key
  })

  response_export_values = ["sshPassword"]
}

module "first_party_sftp_public_user" {
  source = "../modules/services/storage_account_local_user"
  local_user = local.first_party_details.public_user
  storage_account_id = local.first_party_details.account_id
  containers = [
    {
      container_name = local.first_party_details.public_container_name
      user_access = "ro"
    }
  ]
}

module "partner_sftp_public_user" {
  source = "../modules/services/storage_account_local_user"
  local_user = local.partner_details.public_user
  storage_account_id = local.partner_details.account_id
  containers = [
    {
      container_name = local.partner_details.public_container_name
      user_access = "ro"
    }
  ]  
}

resource "azapi_resource_action" "first_party_public_password" {
  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.first_party_sftp_public_user.id
  action = "regeneratePassword"
  body = jsonencode({
  username = local.first_party_details.public_user
  })

  response_export_values = ["sshPassword"]
}

resource "azapi_resource_action" "partner_public_password" {
  type = "Microsoft.Storage/storageAccounts/localUsers@2023-01-01"
  resource_id = module.partner_sftp_public_user.id
  action = "regeneratePassword"
  body = jsonencode({
  username = local.partner_details.public_user
  })

  response_export_values = ["sshPassword"]
}






