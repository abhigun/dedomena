variable "subscription_id" {}
variable "tenant_id" {}
variable "client_id" {}
variable "client_secret" {}

variable "name" {}
variable "location" {}

variable "users" {
  type = map(list(string))
}

variable "storage_account_name" {}
variable "account_tier" {}
variable "account_replication_type" {}
