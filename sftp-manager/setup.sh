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
echo "Step 4: Terraform init"
terraform init -backend-config="resource_group_name=${TF_RESOURCE_GROUP}" -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT}" -backend-config="container_name=${TF_STORAGE_CONTAINER}" -backend-config="key=sftp.tfstate"

echo "Step 5: Terraform Plan"
terraform plan

echo "Step 6: Terraform Apply"
terraform apply --auto-approve

terraform output -json > terraform_output.json