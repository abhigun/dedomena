: '
  Copyright 2023 PhonePe Private Limited

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
'

#!/usr/bin/env bash

echo "Step 1: Pre-Reqs installation"
sudo apt update
sudo apt install curl -y
sudo snap install yq
sudo apt-get install jq
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform

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
export TF_STORAGE_ACCOUNT="tfstatephp"$clientname
export TF_STORAGE_CONTAINER="statecontainer"


client_subscription_id=$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")
client_tenant_id=$(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")
client_tenant_cid=$(yq eval '.client_tenant.client_id' "$ROOT_VALUES")
client_tenant_secret=$(yq eval '.client_tenant.client_secret' "$ROOT_VALUES")

parent_subscription_id=$(yq eval '.parent_tenant.subscription_id' "$ROOT_VALUES")
parent_tenant_id=$(yq eval '.parent_tenant.tenant_id' "$ROOT_VALUES")
parent_tenant_cid=$(yq eval '.parent_tenant.client_id' "$ROOT_VALUES")
parent_tenant_secret=$(yq eval '.parent_tenant.client_secret' "$ROOT_VALUES")


az login --service-principal --username $client_tenant_cid --password $client_tenant_secret --tenant $client_tenant_id
echo "Azure login successfull"

echo "Register required resource providers for creation of storage accounts and insights"
az provider register --namespace 'microsoft.insights'
az provider register --namespace 'Microsoft.OperationalInsights'
az provider register --namespace 'Microsoft.Storage'

# Wait for 2 sec for registering the resource providers
sleep 2

az group create -n $TF_RESOURCE_GROUP -l $TF_LOCATION
echo "Azure terraform resource group created"
az storage account create -n $TF_STORAGE_ACCOUNT -g $TF_RESOURCE_GROUP -l $TF_LOCATION --sku Standard_LRS
echo "Azure terraform storage account created"
az storage container create -n $TF_STORAGE_CONTAINER --account-name $TF_STORAGE_ACCOUNT -g $TF_RESOURCE_GROUP
echo "Azure storage container created"
az role assignment create --assignee "$ARM_CLIENT_ID" --role "Storage Blob Data Owner" --scope "/subscriptions/$client_subscription_id/resourceGroups/$TF_RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$TF_STORAGE_ACCOUNT"
echo "Azure role assignment done"


echo "Step 4: Terraform init"
terraform init -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" -backend-config="container_name=${TF_STORAGE_CONTAINER}" -backend-config="key=infra.tfstate"

echo "Step 5: Terraform Plan"
terraform plan -out=infratfplan

echo "Step 6: Terraform Apply"
terraform apply --auto-approve infratfplan

echo "Step 7: Setup Role for mutitenant APP ID"
az login --service-principal --username $client_tenant_cid --password $client_tenant_secret --tenant $client_tenant_id
az ad sp create --id $parent_tenant_cid || echo "Role creation step done"
az role assignment create --assignee "$parent_tenant_cid" --role "Contributor" --scope "/subscriptions/$client_subscription_id"
echo "Waiting for Role propagation...."
sleep 60

echo "Step 8: Login using multitenant to Client Tenant"
az login --service-principal -u "$parent_tenant_cid" -p "$parent_tenant_secret" --tenant "$parent_tenant_id"

primaryToken=$(az account get-access-token --tenant "$client_tenant_id" -o tsv --query accessToken)
auxToken=$(az account get-access-token --tenant "$parent_tenant_id"  -o tsv --query accessToken)

primaryToken="Bearer $primaryToken"
auxToken="Bearer $auxToken"

echo $primaryToken
echo $auxToken

echo "Step 9: Send Logs"
DiagnosticSettings=$(yq eval '.client_tenant.client_name' "$ROOT_VALUES")
clientSubscriptionResourceId="/subscriptions/$client_subscription_id"
la_resource_group=$(yq eval '.parent_tenant.la_resource_group' "$ROOT_VALUES")
la_storage_account=$(yq eval '.parent_tenant.la_storage_account' "$ROOT_VALUES")
la_workspace=$(yq eval '.parent_tenant.la_workspace' "$ROOT_VALUES")

la_storage_account_id="/subscriptions/$parent_subscription_id/resourceGroups/$la_resource_group/providers/Microsoft.Storage/storageAccounts/$la_storage_account"
la_workspace_id="/subscriptions/$parent_subscription_id/resourceGroups/$la_resource_group/providers/Microsoft.OperationalInsights/workspaces/$la_workspace"
first_party_account_id=$(terraform output storage_account_first_party_id | sed 's/"//g')
partner_account_id=$(terraform output storage_account_partner_id | sed 's/"//g')
dataroom_resource_group=$(terraform output resource_group_name | sed 's/"//g')
synapse_workspace_id=$(terraform output synapse_workspace_id | sed 's/"//g')


uri="https://management.azure.com/subscriptions/$client_subscription_id/providers/Microsoft.Insights/diagnosticSettings/$DiagnosticSettings?api-version=2021-05-01-preview"
az rest --uri $uri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"$la_workspace_id\", \"storageAccountId\": \"$la_storage_account_id\", \"logs\": [{\"categoryGroup\": \"allLogs\",\"enabled\": true}]}}"

echo "Setting up StorageBlob DiagnosticSettings for entities"
firstPartyStorageBlobUri="https://management.azure.com$first_party_account_id/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/storagebloblevel?api-version=2021-05-01-preview"
az rest --uri $firstPartyStorageBlobUri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"$la_workspace_id\", \"storageAccountId\": \"$la_storage_account_id\", \"logs\": [{\"category\": \"StorageRead\",\"enabled\": true}, {\"category\": \"StorageWrite\",\"enabled\": true}, {\"category\": \"StorageDelete\",\"enabled\": true}]}}"

partnerStorageBlobUri="https://management.azure.com$partner_account_id/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/storagebloblevel?api-version=2021-05-01-preview"
az rest --uri $partnerStorageBlobUri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"$la_workspace_id\", \"storageAccountId\": \"$la_storage_account_id\", \"logs\": [{\"category\": \"StorageRead\",\"enabled\": true}, {\"category\": \"StorageWrite\",\"enabled\": true}, {\"category\": \"StorageDelete\",\"enabled\": true}]}}"

echo "Setting up synapse workspace DiagnosticSettings"
synapseUri="https://management.azure.com$la_workspace_id/providers/Microsoft.Insights/diagnosticSettings/synapse?api-version=2021-05-01-preview"
az rest --uri $synapseUri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"$la_workspace_id\", \"storageAccountId\": \"$la_storage_account_id\", \"logs\": [{\"categoryGroup\": \"allLogs\",\"enabled\": true}]}}"


echo "Step 10: Show Credentials"
az logout
az login --service-principal --username $client_tenant_cid --password $client_tenant_secret --tenant $client_tenant_id
keyvault=$(terraform output users_keyvault_name | sed 's/"//g')
echo "SQL Users"
sqlusers=$(yq eval '.sql_administrator_login' "$LOCAL_VALUES")
for name in $sqlusers;
do
  echo "$name: $(az keyvault secret show --name $name --vault-name $keyvault  --query 'value' --output tsv)"
done

terraform output -json > terraform_output.json

echo "Populating values.yaml for sftp and user management"
chmod +x ./populate_values.sh
./populate_values.sh 
