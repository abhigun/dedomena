locals {
  details = yamldecode(file("${path.module}/values.yaml"))
  users = local.details.users
}

locals {
  data_scientist_admin_role = ["Owner", "Synapse Administrator"]
  data_scientist_contributor_role = ["Reader", "Synapse Contributor", "Storage Blob Data Contributor"]
  data_scientist_monitor_role = ["Reader", "Synapse Monitoring User", "Storage Blob Data Reader"]
}

module "ad_users" {
  source              = "../modules/services/azuread_user"
  for_each            = { for i in local.users : i.user_principal_name => i }
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
}

locals {
  user_roles = flatten([
    for user in local.users : [
      for role in user.roles : {
        user_object_id = lookup({for u in local.user_list : u.user_principal_name => u.user_object_id}, user.user_principal_name)
        role_name      = role.name
        role_scope     = role.scope
      }
    ]
  ])
}


module "role_assignments" {
  source               = "../modules/services/role_assignment"
  count                = length(local.user_roles)
  principal_id         = local.user_roles[count.index].user_object_id
  role_definition_name = local.user_roles[count.index].role_name
  scope                = local.user_roles[count.index].role_scope
}