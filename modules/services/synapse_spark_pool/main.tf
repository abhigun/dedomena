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

resource "random_id" "wrkspcname" {
  byte_length = 5
  prefix = var.name
}


module "kv_secret" {
  source = "../key_vault_secret"
  name = var.sql_administrator_login
  value = module.password.password
  key_vault_id = var.key_vault_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "fs" {
  name               = var.name
  storage_account_id = var.storage_account_id
}

resource "azurerm_synapse_workspace" "sw" {
  name                                 = "${lower(random_id.wrkspcname.hex)}wkspc"
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.fs.id
  sql_administrator_login              = var.sql_administrator_login #"sqladminuser"
  sql_administrator_login_password     = module.password.password #"H@Sh1CoR3!"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_spark_pool" "ssp" {
  name                 = var.name
  synapse_workspace_id = azurerm_synapse_workspace.sw.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100

  auto_scale {
    max_node_count = 50
    min_node_count = 3
  }

  auto_pause {
    delay_in_minutes = 15
  }

  library_requirement {
    content  = <<EOF
appnope==0.1.0
beautifulsoup4==4.6.3
EOF
    filename = "requirements.txt"
  }

  spark_config {
    content  = <<EOF
spark.shuffle.spill                true
EOF
    filename = "config.txt"
  }

  tags = {
    ENV = "Dev"
  }
}
