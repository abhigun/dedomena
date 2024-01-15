az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)

echo "Updating sftp property to $1"
az storage account update --default-action Allow --name $(yq eval '.storage_account_name' values.yaml) --resource-group $(yq eval '.resource_group_name' values.yaml) --enable-sftp $1
az logout 