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
resource "azurerm_log_analytics_workspace" "sentinel_workspace" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku #"PerGB2018"
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "workspace_onboarding" {
  workspace_id = azurerm_log_analytics_workspace.sentinel_workspace.id
}