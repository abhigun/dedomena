output "user_principal_name" {
  value = azuread_user.ad_user.user_principal_name
}

output "user_object_id" {
  value = azuread_user.ad_user.object_id
}
