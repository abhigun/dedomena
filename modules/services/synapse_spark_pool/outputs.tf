output "workspace_id" {
  value = azurerm_synapse_workspace.sw.id
}

output "workspace_name" {
  value = azurerm_synapse_workspace.sw.name	
}

output "storage_account_name" {
  value = module.storage_account_synapse.storage_account
}

output "storage_account_id" {
  value = module.storage_account_synapse.storage_account_id
}