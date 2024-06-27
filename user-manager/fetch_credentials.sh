#!/usr/bin/env bash

# script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the values from the relative path
ROOT_VALUES="$SCRIPT_DIR/../values.yaml"
LOCAL_VALUES="$SCRIPT_DIR/values.yaml"

az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")

first_party_users=$(yq eval '.first_party_details.users[].nick_name' "$LOCAL_VALUES")
partner_users=$(yq eval '.partner_details.users[].nick_name' "$LOCAL_VALUES")
keyvault=$(yq eval '.key_vault_name' "$LOCAL_VALUES" | sed 's/"//g')
echo "First Party Azure Entra Users"
for name in $first_party_users;
do
  echo "$name: $(az keyvault secret show --name $name --vault-name $keyvault  --query 'value' --output tsv)"
done

echo "\nPartner Azure Entra Users"
for name in $partner_users;
do
  echo "$name: $(az keyvault secret show --name $name --vault-name $keyvault  --query 'value' --output tsv)"
done

az logout
