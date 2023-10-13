output "values" {
  value = module.ad_users
}

output "users_keyvault" {
  value = module.az_kv.key_vault
}

output "user_object_ids" {
  value = [for user in local.user_list : user.user_object_id]
}