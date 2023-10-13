module "resource_group" {
  source   = "./modules/services/resource_group"
  name     = "${var.name}-rg"
  location = var.location
}

locals {
  users = yamldecode(file("${path.module}/values.yaml")).users
}

module "az_kv" {
  source         = "./modules/services/key_vault"
  name           = "azusers"
  location       = module.resource_group.resource-location
  resource_group = module.resource_group.resource-grp
}

module "ad_users" {
  source              = "./modules/services/azuread_user"
  for_each            = { for i in local.users : i.user => i }
  user_principal_name = each.key
  display_name        = each.value.display_name
  mail_nickname       = each.value.nick_name
  name                = each.value.nick_name
  key_vault_id        = module.az_kv.key_vault_id
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
  user_object_ids = [for user in local.user_list : user.user_object_id]
}

#module "ad_invitation" {
#  source  = "../modules/services/azuread_invitation"
#  user_email_address   = "manikandan.subramanian@rapyder.com"
#}

module "storage_account" {
  source                   = "./modules/services/storage_account"
  name                     = yamldecode(file("${path.module}/values.yaml")).client_tenant.client_name
  resource_group_name      = module.resource_group.resource-grp
  location                 = module.resource_group.resource-location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = false
  sftp_enabled             = false

}

module "storage_container" {
  source                = "./modules/services/storage_container"
  count                 = length(local.user_object_ids)
  name                  = "testcon-${count.index}"
  storage_account_name  = module.storage_account.storage_account
  container_access_type = "private"
}

module "storage_container_common_role_assignment" {
  source               = "./modules/services/role_assignment"
#  count                = length(keys(var.users))
  count                = length(local.user_object_ids)
#  principal_id         = module.ad_users.*.user_object_id[count.index]
  principal_id         = local.user_object_ids[count.index]
  role_definition_name = "Reader"
  scope                = module.storage_account.storage_account_id
}

module "storage_container_contributor_role_assignment" {
  source               = "./modules/services/role_assignment"
  count                = length(local.user_object_ids)
#  principal_id         = module.ad_users.*.user_object_id[count.index]
  principal_id         = local.user_object_ids[count.index]
  role_definition_name = "Storage Blob Data Contributor"
  scope                = module.storage_container.*.storage_container_id[count.index]
}

locals {
#  reverse_users_ids = reverse(module.ad_users.*.user_object_id)
  reverse_users_ids = reverse(local.user_object_ids)
}

module "storage_container_reader_role_assignment" {
  source               = "./modules/services/role_assignment"
  count                = length(local.user_object_ids)
  principal_id         = local.reverse_users_ids[count.index]
  role_definition_name = "Storage Blob Data Reader"
  scope                = module.storage_container.*.storage_container_id[count.index]
}

## ML Workspace
#module "ml_workspace" {
#  source   = "../modules/services/ml_workspace"
#  name     = "demomlrap"
#  location = "centralindia"
#}

module "storage_account_sftp" {
  source                   = "./modules/services/storage_account"
  name                     = "demosftp" #"demousersssftp"
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

module "synapse_spark" {
  source                           = "./modules/services/synapse_spark_pool"
  name                             = var.name
  resource_group_name              = module.resource_group.resource-grp
  location                         = module.resource_group.resource-location
#  sql_administrator_login          = "sqladminuser"
  sql_administrator_login         = yamldecode(file("${path.module}/values.yaml")).sql_administrator_login
  key_vault_id                     = module.az_kv.key_vault_id
#  sql_administrator_login_password = "H@Sh1CoR3!"
  storage_account_id               = module.storage_account_sftp.storage_account_id
}
