#!/bin/bash

terraform_output=$(cat terraform_output.json)
# script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the values from the relative path
ROOT_VALUES="$SCRIPT_DIR/../values.yaml"
LOCAL_VALUES="$SCRIPT_DIR/values.yaml"

subscriptionId="$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")"
dataroom_name="$(yq eval '.name' "$LOCAL_VALUES")"

resource_group_name=$(echo "$terraform_output" | jq -r .resource_group_name.value)
key_vault_name=$(echo "$terraform_output" | jq -r .users_keyvault_name.value)
key_vault_id=$(echo "$terraform_output" | jq -r .users_keyvault_id.value)
synapse_workspace_id=$(echo "$terraform_output" | jq -r .synapse_workspace_id.value)
synapse_workspace_name=$(echo "$terraform_output" | jq -r .synapse_workspace_name.value)
synapse_storage_account_id=$(echo "$terraform_output" | jq -r .synapse_storage_account_id.value)
synapse_storage_container_id="$synapse_storage_account_id/blobServices/default/containers/$dataroom_name"


# First Party account & containers details 
first_party_account_name=$(echo "$terraform_output" | jq -r .storage_account_first_party_name.value)
first_party_account_id=$(echo "$terraform_output" | jq -r .storage_account_first_party_id.value)
first_party_private_container_name=$(echo "$terraform_output" | jq -r .first_party_private_container_name.value)
first_party_public_container_name=$(echo "$terraform_output" | jq -r .first_party_public_container_name.value)
first_party_private_container_id=$(echo "$terraform_output" | jq -r .first_party_private_container_id.value)
first_party_public_container_id=$(echo "$terraform_output" | jq -r .first_party_public_container_id.value)


# Partner account & containers details
partner_account_name=$(echo "$terraform_output" | jq -r .storage_account_partner_name.value)
partner_account_id=$(echo "$terraform_output" | jq -r .storage_account_partner_id.value)
partner_private_container_name=$(echo "$terraform_output" | jq -r .partner_private_container_name.value)
partner_public_container_name=$(echo "$terraform_output" | jq -r .partner_public_container_name.value)
partner_private_container_id=$(echo "$terraform_output" | jq -r .partner_private_container_id.value)
partner_public_container_id=$(echo "$terraform_output" | jq -r .partner_public_container_id.value)


# Function to update a yaml file
update_yaml() {
  local file_path=$1
  shift
  local updates=("$@")
  for update in "${updates[@]}"; do
    yq eval-all "$update" "$file_path" -i
  done
}

# Updates for ../sftp-manager/values.yaml
sftp_manager_updates=(
  ".resource_group_name |= \"$resource_group_name\" | .key_vault_id |= \"$key_vault_id\" | .key_vault_name |= \"$key_vault_name\""
  ".first_party_details.account_name |= \"$first_party_account_name\" | .first_party_details.account_id |= \"$first_party_account_id\" | .first_party_details.private_container_name |= \"$first_party_private_container_name\" | .first_party_details.public_container_name |= \"$first_party_public_container_name\""
  ".partner_details.account_name |= \"$partner_account_name\" | .partner_details.account_id |= \"$partner_account_id\" | .partner_details.private_container_name |= \"$partner_private_container_name\" | .partner_details.public_container_name |= \"$partner_public_container_name\""
)

# Updates for ../user-manager/values.yaml
user_manager_updates=(
  ".subscription_id |= \"$subscriptionId\" | .resource_group_name |= \"$resource_group_name\" | .key_vault_id |= \"$key_vault_id\" | .key_vault_name |= \"$key_vault_name\" | .synapse_workspace_name |= \"$synapse_workspace_name\" | .synapse_storage_container_id |= \"$synapse_storage_container_id\""
  ".first_party_details.account_name |= \"$first_party_account_name\" | .first_party_details.account_id |= \"$first_party_account_id\" | .first_party_details.private_container_name |= \"$first_party_private_container_name\" | .first_party_details.private_container_id |= \"$first_party_private_container_id\" | .first_party_details.public_container_id |= \"$first_party_public_container_id\" | .first_party_details.public_container_name |= \"$first_party_public_container_name\""
  ".partner_details.account_name |= \"$partner_account_name\" | .partner_details.account_id |= \"$partner_account_id\" | .partner_details.private_container_name |= \"$partner_private_container_name\" | .partner_details.private_container_id |= \"$partner_private_container_id\" | .partner_details.public_container_id |= \"$partner_public_container_id\" | .partner_details.public_container_name |= \"$partner_public_container_name\""
)


update_yaml "../sftp-manager/values.yaml" "${sftp_manager_updates[@]}"
update_yaml "../user-manager/values.yaml" "${user_manager_updates[@]}"
