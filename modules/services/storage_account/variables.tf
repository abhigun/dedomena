variable "name" {}
variable "resource_group_name" {}
variable "location" {}
variable "account_tier" {}
variable "account_replication_type" {}

variable "sftp_enabled" {
  type = bool
}
variable "is_hns_enabled" {
  type = bool
}
