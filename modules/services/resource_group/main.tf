resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = var.name
  tags = {
    Name        = var.name
#    project     = var.project
#    Location    = var.location
#    environment = var.env
  }
  lifecycle {
    ignore_changes = [tags]
  }
}