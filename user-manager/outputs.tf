output "values" {
  value = module.ad_users
}

output "user_object_ids" {
  value = [for user in local.user_list : user.user_object_id]
}

output "role_list" {
  value = local.user_role_list
}