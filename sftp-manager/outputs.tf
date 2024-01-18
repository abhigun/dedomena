output "sftpmod" {
  value = azapi_resource_action.sftpPassword
}

output "sftp_container_id" {
  value = module.storage_container.storage_container_id
}