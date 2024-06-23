#!/usr/bin/env bash

# script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the values from the relative path
ROOT_VALUES="$SCRIPT_DIR/../values.yaml"
LOCAL_VALUES="$SCRIPT_DIR/values.yaml"

echo "Step 2: Setup Client Credentials as ENVIRONMENT"
export ARM_CLIENT_ID="$(yq eval '.client_tenant.client_id' "$ROOT_VALUES")"
export ARM_CLIENT_SECRET="$(yq eval '.client_tenant.client_secret' "$ROOT_VALUES")"
export ARM_SUBSCRIPTION_ID="$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")"
export ARM_TENANT_ID="$(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")"

echo "Step 3: Create Terraform Backend"
clientname=$(yq eval '.client_tenant.client_name' "$ROOT_VALUES")
export TENANT="phonepe"
export TF_RESOURCE_GROUP="terraform"
export TF_LOCATION="centralindia"
export TF_STORAGE_ACCOUNT="tfstatephpstage"$clientname
export TF_STORAGE_CONTAINER="statecontainer"

az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")

echo "Step 4: Terraform init"
terraform init -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" -backend-config="container_name=${TF_STORAGE_CONTAINER}" -backend-config="key=usermanagers5.tfstate"

echo "Step 5: Terraform Plan"
terraform plan -out=userplan

echo "Step 6: Terraform Apply"
terraform apply --auto-approve userplan

terraform output -json > terraform_output.json

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
