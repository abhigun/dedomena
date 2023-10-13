resource "azuread_invitation" "example" {
  user_email_address = var.user_email_address
  redirect_url       = "https://portal.azure.com"

  message {
    language = "en-US"
  }
}
