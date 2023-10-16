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


