#!/usr/bin/env bash

echo "Step 1: Pre-Reqs installation\n"
# Making the manage sftp executable 
chmod +x "./manage_sftp.sh"

echo "Step 2: Setup Client Credentials as ENVIRONMENT\n"
export ARM_CLIENT_ID="$(yq eval '.client_tenant.client_id' ../values.yaml)"
export ARM_CLIENT_SECRET="$(yq eval '.client_tenant.client_secret' ../values.yaml)"
export ARM_SUBSCRIPTION_ID="$(yq eval '.client_tenant.subscription_id' ../values.yaml)"
export ARM_TENANT_ID="$(yq eval '.client_tenant.tenant_id' ../values.yaml)"

echo "Step 3: Create Terraform Backend\n"
clientname=$(yq eval '.client_tenant.client_name' ../values.yaml)
export TENANT="phonepe"
export TF_RESOURCE_GROUP="terraform"
export TF_LOCATION="centralindia"
export TF_STORAGE_ACCOUNT="tfstatephpstage"$clientname
export TF_STORAGE_CONTAINER="statecontainer"

az login --service-principal --username $(yq eval '.client_tenant.client_id' ../values.yaml) --password $(yq eval '.client_tenant.client_secret' ../values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' ../values.yaml)
echo "Step 4: Terraform init\n"
terraform init -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" -backend-config="container_name=${TF_STORAGE_CONTAINER}" -backend-config="key=sftp2.tfstate"

echo "Step 5: Terraform Plan\n"
terraform plan

echo "Step 6: Terraform Apply\n"
terraform apply --auto-approve

first_party_account_name=$(yq eval '.first_party_details.account_name' values.yaml)
first_party_private_container_name=$(yq eval '.first_party_details.private_container_name' values.yaml)
first_party_public_container_name=$(yq eval '.first_party_details.public_container_name' values.yaml)
first_party_public_user=$(yq eval '.first_party_details.public_user' values.yaml)

echo "\n"
echo "First party private container sftp connection string\n"
echo "${first_party_account_name}.${first_party_private_container_name}.<username>@${first_party_account_name}.blob.core.windows.net"

echo "\nFirst party public container sftp connection string\n"
echo "${first_party_account_name}.${first_party_public_container_name}.${first_party_public_user}${first_party_account_name}.blob.core.windows.net"

partner_account_name=$(yq eval '.partner_details.account_name' values.yaml)
partner_private_container_name=$(yq eval '.partner_details.private_container_name' values.yaml)
partner_public_container_name=$(yq eval '.partner_details.public_container_name' values.yaml)
partner_public_user=$(yq eval '.partner_details.public_user' values.yaml)

echo "\nPartner private container sftp connection string\n"
echo "${partner_account_name}.${partner_private_container_name}.<username>@${partner_account_name}.blob.core.windows.net"

echo "\nPartner public container sftp connection string\n"
echo "${partner_account_name}.${partner_public_container_name}.${partner_public_user}@${partner_account_name}.blob.core.windows.net"

terraform output -json > terraform_output.json
