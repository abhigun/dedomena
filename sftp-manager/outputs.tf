output "first_party_private_user_passwords" {
  description = "A map of first-party usernames to their generated passwords"
  value = {
    for user in local.first_party_users :
    user => jsondecode(azapi_resource_action.first_party_private_passwords[user].output).sshPassword
  }
}

output "partner_private_user_passwords" {
  description = "A map of partner usernames to their generated passwords"
  value = {
    for user in local.partner_users :
    user => jsondecode(azapi_resource_action.partner_private_passwords[user].output).sshPassword
  }
}

output "first_party_public_user_password" {
  value = jsondecode(azapi_resource_action.first_party_public_password.output).sshPassword
}

output "partner_public_user_password" {
  value = jsondecode(azapi_resource_action.partner_public_password.output).sshPassword
}
