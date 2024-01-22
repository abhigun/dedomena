output "sftp_password" {
  value = jsondecode(azapi_resource_action.sftpPassword.output).sshPassword
}

output "sftp_container_id" {
  value = module.storage_container.storage_container_id
}