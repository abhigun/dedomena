resource "random_id" "saname" {
  byte_length = 5
  prefix = var.name
}

resource "azurerm_storage_account" "storage_account" {
  name                     = random_id.saname.hex
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

#  sftp_enabled = var.sftp_enabled
  is_hns_enabled = var.is_hns_enabled

  tags = {
    Name = var.name
  }
}
