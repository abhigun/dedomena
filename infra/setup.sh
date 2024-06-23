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
export TF_STORAGE_ACCOUNT="tfstatephpstage"$clientname
export TF_STORAGE_CONTAINER="statecontainer"

az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")
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
az role assignment create --assignee "$ARM_CLIENT_ID" --role "Storage Blob Data Owner" --scope "/subscriptions/$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$TF_RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$TF_STORAGE_ACCOUNT"
echo "Azure role assignment done"


echo "Step 4: Terraform init"
terraform init -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" -backend-config="container_name=${TF_STORAGE_CONTAINER}" -backend-config="key=infra.tfstate"

echo "Step 5: Terraform Plan"
terraform plan -out=infraplan

echo "Step 6: Terraform Apply"
terraform apply --auto-approve infraplan

echo "Step 7: Setup Role for mutitenant APP ID"
az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")
az ad sp create --id $(yq eval '.parent_tenant.client_id' "$ROOT_VALUES") || echo "Role creation step done"
az role assignment create --assignee "$(yq eval '.parent_tenant.client_id' "$ROOT_VALUES")" --role "Contributor" --scope "/subscriptions/$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")"
echo "Waiting for Role propagation...."
sleep 60

echo "Step 8: Login using multitenant to Client Tenant"
az login --service-principal -u "$(yq eval '.parent_tenant.client_id' "$ROOT_VALUES")" -p "$(yq eval '.parent_tenant.client_secret' "$ROOT_VALUES")" --tenant "$(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")"

primaryToken=$(az account get-access-token --tenant "$(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")" -o tsv --query accessToken)
auxToken=$(az account get-access-token --tenant "$(yq eval '.parent_tenant.tenant_id' "$ROOT_VALUES")"  -o tsv --query accessToken)

primaryToken="Bearer $primaryToken"
auxToken="Bearer $auxToken"

echo $primaryToken
echo $auxToken

echo "Step 9: Send Logs"
DiagnosticSettings=$(yq eval '.client_tenant.client_name' "$ROOT_VALUES")
uri="https://management.azure.com/subscriptions/$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")/providers/Microsoft.Insights/diagnosticSettings/$DiagnosticSettings?api-version=2021-05-01-preview"
az rest --uri $uri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"/subscriptions/$(yq eval '.parent_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$(yq eval '.parent_tenant.la_resource_group' "$ROOT_VALUES")/providers/Microsoft.OperationalInsights/workspaces/$(yq eval '.parent_tenant.la_workspace' "$ROOT_VALUES")\",\"logs\": [{\"categoryGroup\": \"allLogs\",\"enabled\": true}]}}"

echo "Fetching SFTP Storage Account and dataroom resource group"
first_party_account_name=$(terraform output storage_account_first_party_name | sed 's/"//g')
partner_account_name=$(terraform output storage_account_partner_name | sed 's/"//g')

dataroom_resource_group=$(terraform output resource_group_name | sed 's/"//g')
synapse_workspace_name=$(terraform output synapse_workspace_name | sed 's/"//g')

echo "Setting up StorageBlob DiagnosticSettings for entities"
firstPartyStorageBlobUri="https://management.azure.com/subscriptions/$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$dataroom_resource_group/providers/Microsoft.Storage/storageAccounts/$first_party_account_name/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/storagebloblevel?api-version=2021-05-01-preview"
az rest --uri $firstPartyStorageBlobUri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"/subscriptions/$(yq eval '.parent_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$(yq eval '.parent_tenant.la_resource_group' "$ROOT_VALUES")/providers/Microsoft.OperationalInsights/workspaces/$(yq eval '.parent_tenant.la_workspace' "$ROOT_VALUES")\",\"logs\": [{\"category\": \"StorageRead\",\"enabled\": true}, {\"category\": \"StorageWrite\",\"enabled\": true}, {\"category\": \"StorageDelete\",\"enabled\": true}]}}"

partnerStorageBlobUri="https://management.azure.com/subscriptions/$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$dataroom_resource_group/providers/Microsoft.Storage/storageAccounts/$partner_account_name/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/storagebloblevel?api-version=2021-05-01-preview"
az rest --uri $partnerStorageBlobUri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"/subscriptions/$(yq eval '.parent_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$(yq eval '.parent_tenant.la_resource_group' "$ROOT_VALUES")/providers/Microsoft.OperationalInsights/workspaces/$(yq eval '.parent_tenant.la_workspace' "$ROOT_VALUES")\",\"logs\": [{\"category\": \"StorageRead\",\"enabled\": true}, {\"category\": \"StorageWrite\",\"enabled\": true}, {\"category\": \"StorageDelete\",\"enabled\": true}]}}"

echo "Setting up synapse workspace DiagnosticSettings"
synapseUri="https://management.azure.com/subscriptions/$(yq eval '.client_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$dataroom_resource_group/providers/Microsoft.Synapse/workspaces/$synapse_workspace_name/providers/Microsoft.Insights/diagnosticSettings/synapse?api-version=2021-05-01-preview"
az rest --uri $synapseUri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"/subscriptions/$(yq eval '.parent_tenant.subscription_id' "$ROOT_VALUES")/resourceGroups/$(yq eval '.parent_tenant.la_resource_group' "$ROOT_VALUES")/providers/Microsoft.OperationalInsights/workspaces/$(yq eval '.parent_tenant.la_workspace' "$ROOT_VALUES")\",\"logs\": [{\"categoryGroup\": \"allLogs\",\"enabled\": true}]}}"

echo "Step 10: Show Credentials"
az logout
az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")
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
