locals {
  details = yamldecode(file("${path.module}/values.yaml"))
  users = details.users
}

module "ad_users" {
  source              = "../modules/services/azuread_user"
  for_each            = { for i in local.users : i.princal_name => i }
  user_principal_name = each.key
  display_name        = each.value.display_name
  mail_nickname       = each.value.nick_name
  name                = each.value.nick_name
  key_vault_id        = local.details.key_vault_id
}

# Convert the map of objects into a list of maps
locals {
  user_list = [
    for email, user_info in module.ad_users : {
      email            = email
      user_object_id   = user_info.user_object_id
      user_principal_name = user_info.user_principal_name
    }
  ]
  user_role_list = flatten([for user in local.users : [
    for role in user.roles : {
      role_name      = role.name
      role_scope     = role.scope
      user_id   = lookup([for u in local.user_list : { u.user_principal_name => u.user_id }], user.princal_name, null)
    }
  ]])
}


module "role_assignments" {
  source               = "../modules/services/role_assignment"
  count                = length(local.user_role_list)
  principal_id         = local.user_role_list[count.index].user_id
  role_definition_name = local.user_role_list[count.index].role_name
  scope                = local.user_role_list[count.index].role_scope
}



# locals {
#   user_object_ids = [for user in local.user_list : user.user_object_id]
# }

# module "storage_account" {
#   source                   = "../modules/services/storage_account"
#   name                     = yamldecode(file("${path.module}/values.yaml")).client_tenant.client_name
#   resource_group_name      = module.resource_group.resource-grp
#   location                 = module.resource_group.resource-location
#   account_tier             = var.account_tier
#   account_replication_type = var.account_replication_type
#   is_hns_enabled           = false
#   sftp_enabled             = false

# }

# module "storage_container" {
#   source                = "../modules/services/storage_container"
#   count                 = length(local.user_object_ids)
#   name                  = "testcon-${count.index}"
#   storage_account_name  = module.storage_account.storage_account
#   container_access_type = "private"
# }


# module "storage_container_contributor_role_assignment" {
#   source               = "../modules/services/role_assignment"
#   count                = length(local.user_object_ids)
#   principal_id         = local.user_object_ids[count.index]
#   role_definition_name = "Storage Blob Data Contributor"
#   scope                = module.storage_container.*.storage_container_id[count.index]
# }

# locals {
#   reverse_users_ids = reverse(local.user_object_ids)
# }

# module "storage_container_reader_role_assignment" {
#   source               = "../modules/services/role_assignment"
#   count                = length(local.user_object_ids)
#   principal_id         = local.reverse_users_ids[count.index]
#   role_definition_name = "Storage Blob Data Reader"
#   scope                = module.storage_container.*.storage_container_id[count.index]
# }