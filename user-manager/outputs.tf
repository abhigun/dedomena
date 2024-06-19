output "first_party_ad_users" {
  description = "User Principal Names and Object IDs of first party AD users"
  value = {
    for user_key, user in module.first_party_ad_users :
    user_key => {
      object_id           = user.user_object_id
    }
  }
}

output "partner_ad_users" {
  description = "User Principal Names and Object IDs of partner AD users"
  value = {
    for user_key, user in module.partner_ad_users :
    user_key => {
      object_id           = user.user_object_id
    }
  }
}
