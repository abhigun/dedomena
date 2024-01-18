export ARM_CLIENT_ID="$(yq eval '.client_tenant.client_id' values.yaml)"
export ARM_CLIENT_SECRET="$(yq eval '.client_tenant.client_secret' values.yaml)"
export ARM_SUBSCRIPTION_ID="$(yq eval '.client_tenant.subscription_id' values.yaml)"
export ARM_TENANT_ID="$(yq eval '.client_tenant.tenant_id' values.yaml)"

echo "Step 1: Destroy Infrastructure"
az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)

terraform destroy 