locals {
  details = yamldecode(file("${path.module}/values.yaml"))
  first_party_users = length(local.details.first_party_details.users) > 0 ? local.details.first_party_details.users : {}
  partner_users = length(local.details.partner_details.users) > 0 ? local.details.partner_details.users : {}

}

module "first_party_ad_users" {
  source              = "../modules/services/azuread_user"
  for_each            = { for i in local.first_party_users : i.user_principal_name => i }
  user_principal_name = each.key
  display_name        = each.value.display_name
  mail_nickname       = each.value.nick_name
  name                = each.value.nick_name
  key_vault_id        = local.details.key_vault_id
}


module "partner_ad_users" {
  source              = "../modules/services/azuread_user"
  for_each            = { for i in local.partner_users : i.user_principal_name => i }
  user_principal_name = each.key
  display_name        = each.value.display_name
  mail_nickname       = each.value.nick_name
  name                = each.value.nick_name
  key_vault_id        = local.details.key_vault_id
}
