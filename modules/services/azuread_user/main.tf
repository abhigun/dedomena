module "password" {
  source = "../random_password"
}

resource "azuread_user" "ad_user" {
  user_principal_name = var.user_principal_name   #"jdoe@hashicorp.com"
  display_name        = var.display_name          #"J. Doe"
  mail_nickname       = var.mail_nickname         #"jdoe"
  password            = module.password.password  #"SecretP@sswd99!"
}

module "kv_secret" {
  source = "../key_vault_secret"
  name = var.name
  value = module.password.password
  key_vault_id = var.key_vault_id
}


