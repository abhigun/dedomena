resource "azurerm_storage_account_local_user" "local_user" {
  name                 = var.local_user
  storage_account_id   = var.storage_account_id
  ssh_key_enabled      = false
  ssh_password_enabled = true
  permission_scope {
    permissions {
      read   = true
      create = true
      write  = true
      delete = true
      list   = true
    }
    service       = "blob"
    resource_name = var.resource_name
  }
}
