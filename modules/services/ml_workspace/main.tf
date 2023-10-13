data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.name}-ml-rg"
  location = var.location
}

resource "azurerm_application_insights" "application_insights" {
  name                = "${var.name}-ml-ins"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "web"
}

resource "azurerm_key_vault" "key_vault" {
  name                = "${var.name}-ml-kv"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${var.name}mlsa"
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_machine_learning_workspace" "machine_learning_workspace" {
  name                    = "${var.name}-workspace"
  location                = azurerm_resource_group.resource_group.location
  resource_group_name     = azurerm_resource_group.resource_group.name
  application_insights_id = azurerm_application_insights.application_insights.id
  key_vault_id            = azurerm_key_vault.key_vault.id
  storage_account_id      = azurerm_storage_account.storage_account.id


  identity {
    type = "SystemAssigned"
  }
}
