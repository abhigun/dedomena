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

echo "Step 1: Pre-requesties installation"
sudo apt update
sudo apt install curl -y
sudo snap install yq
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform

echo "Step 2: Setup Client Credentials as ENVIRONMENT"
export ARM_CLIENT_ID="$(yq eval '.client_tenant.client_id' values.yaml)"
export ARM_CLIENT_SECRET="$(yq eval '.client_tenant.client_secret' values.yaml)"
export ARM_SUBSCRIPTION_ID="$(yq eval '.client_tenant.subscription_id' values.yaml)"
export ARM_TENANT_ID="$(yq eval '.client_tenant.tenant_id' values.yaml)"

echo "Step 3: Create Terraform Backend"
clientname=$(yq eval '.client_tenant.client_name' values.yaml)
export TENANT="phonepe"
export TF_RESOURCE_GROUP="terraform"
export TF_LOCATION="centralindia"
export TF_STORAGE_ACCOUNT="tfstatephpe"$clientname
export TF_STORAGE_CONTAINER="statecontainer"

az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)
az group create -n $TF_RESOURCE_GROUP -l $TF_LOCATION
az storage account create -n $TF_STORAGE_ACCOUNT -g $TF_RESOURCE_GROUP -l $TF_LOCATION --sku Standard_LRS
az storage container create -n $TF_STORAGE_CONTAINER --account-name $TF_STORAGE_ACCOUNT -g $TF_RESOURCE_GROUP
az role assignment create --assignee "$ARM_CLIENT_ID" --role "Storage Blob Data Owner" --scope "/subscriptions/$(yq eval '.client_tenant.subscription_id' values.yaml)/resourceGroups/$TF_RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$TF_STORAGE_ACCOUNT"


echo "Step 3: Terraform init"
terraform init -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" -backend-config="container_name=${TF_STORAGE_CONTAINER}" -backend-config="key=pocstatefile"

echo "Step 4: Terraform Plan"
terraform plan

echo "Step 5: Terraform Apply"
terraform apply --auto-approve

echo "Step 6: Show Secrets"
users=$(yq eval '.users[].nick_name' values.yaml)
keyvault=$(terraform output users_keyvault | sed 's/"//g')
for name in $users;
do
  echo "$name: $(az keyvault secret show --name $name --vault-name $keyvault  --query 'value' --output tsv)"
done

echo "Step 7: Setup Role for mutitenant APP ID"
az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)
az ad sp create --id $(yq eval '.parent_tenant.client_id' values.yaml) || echo "Role creation step done"
az role assignment create --assignee "$(yq eval '.parent_tenant.client_id' values.yaml)" --role "Contributor" --scope "/subscriptions/$(yq eval '.client_tenant.subscription_id' values.yaml)"
echo "Waiting for Role propagation...."
sleep 60

echo "Step 8: Login using multitenant to Client Tenant"
az login --service-principal -u "$(yq eval '.parent_tenant.client_id' values.yaml)" -p "$(yq eval '.parent_tenant.client_secret' values.yaml)" --tenant "$(yq eval '.client_tenant.tenant_id' values.yaml)"

primaryToken=$(az account get-access-token --tenant "$(yq eval '.client_tenant.tenant_id' values.yaml)" -o tsv --query accessToken)
auxToken=$(az account get-access-token --tenant "$(yq eval '.parent_tenant.tenant_id' values.yaml)"  -o tsv --query accessToken)

primaryToken="Bearer $primaryToken"
auxToken="Bearer $auxToken"

echo $primaryToken
echo $auxToken

echo "Step 9: Send Logs"
DiagnosticSettings=$(yq eval '.client_tenant.client_name' values.yaml)
uri="https://management.azure.com/subscriptions/$(yq eval '.client_tenant.subscription_id' values.yaml)/providers/Microsoft.Insights/diagnosticSettings/$DiagnosticSettings?api-version=2021-05-01-preview"
az rest --uri $uri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"workspaceId\": \"/subscriptions/$(yq eval '.parent_tenant.subscription_id' values.yaml)/resourceGroups/$(yq eval '.parent_tenant.la_resource_group' values.yaml)/providers/Microsoft.OperationalInsights/workspaces/$(yq eval '.parent_tenant.la_workspace' values.yaml)\",\"logs\": [{\"categoryGroup\": \"allLogs\",\"enabled\": true}]}}"
#az rest --uri $uri --method PUT --skip-authorization-header --headers Authorization="$primaryToken" x-ms-authorization-auxiliary="$auxToken" ContentType="application/json" --body "{\"properties\": {\"storageAccountId\": \"/subscriptions/$(yq eval '.parent_tenant.subscription_id' values.yaml)/resourceGroups/$(yq eval '.parent_tenant.resource_group' values.yaml)/providers/Microsoft.Storage/storageAccounts/$(yq eval '.parent_tenant.storage_account' values.yaml)\",\"logs\": [{\"categoryGroup\": \"allLogs\",\"enabled\": true}]}}"


echo "Step 6: Show Secrets"
az logout
az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)
users=$(yq eval '.users[].nick_name' values.yaml)
keyvault=$(terraform output users_keyvault | sed 's/"//g')
echo "Azure Entra Users"
for name in $users;
do
  echo "$name: $(az keyvault secret show --name $name --vault-name $keyvault  --query 'value' --output tsv)"
done
echo "SQL Users"
sqlusers=$(yq eval '.sql_administrator_login' values.yaml)
for name in $sqlusers;
do
  echo "$name: $(az keyvault secret show --name $name --vault-name $keyvault  --query 'value' --output tsv)"
done
