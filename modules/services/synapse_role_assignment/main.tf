resource "azurerm_synapse_role_assignment" "synapse_ra" {
  synapse_workspace_id = var.workspace_id
  role_name            = var.role_definition_name
  principal_id         = var.principal_id
}