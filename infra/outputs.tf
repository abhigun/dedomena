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

output "users_keyvault_name" {
  value = module.az_kv.key_vault
}

output "users_keyvault_id" {
  value = module.az_kv.key_vault_id
}

output "storage_account_first_party_name" {
  value = module.storage_account_first_party.storage_account
}

output "storage_account_first_party_id" {
  value = module.storage_account_first_party.storage_account_id
}

output "storage_account_partner_name" {
  value = module.storage_account_partner.storage_account
}

output "storage_account_partner_id" {
  value = module.storage_account_partner.storage_account_id
}

output "first_party_private_container_id" {
 value = module.first_party_container_private.storage_container_id
}

output "first_party_private_container_name" {
 value = module.first_party_container_private.storage_container_name
}

output "first_party_public_container_id" {
 value = module.first_party_container_public.storage_container_id
}

output "first_party_public_container_name" {
 value = module.first_party_container_public.storage_container_name
}

output "partner_private_container_id" {
 value = module.partner_container_private.storage_container_id
}

output "partner_public_container_id" {
 value = module.partner_container_public.storage_container_id
}

output "partner_private_container_name" {
 value = module.partner_container_private.storage_container_name
}

output "partner_public_container_name" {
 value = module.partner_container_public.storage_container_name
}

output "resource_group_name" {
  value = module.resource_group.resource-grp
}

output "synapse_workspace_id" {
  value = module.synapse_spark.workspace_id
}

output "synapse_workspace_name" {
  value = module.synapse_spark.workspace_name
}

output "synapse_storage_account_name" {
  value = module.synapse_spark.storage_account_name
}

output "synapse_storage_account_id" {
  value = module.synapse_spark.storage_account_id
}
