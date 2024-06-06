# Define variables
subscriptionId="9d027377-65d9-4a24-b56e-a43fd77785ce"
storageAccountName="payusftp1fa1646cd5"
synapseStorageContainer="dataroominfra"
resourceGroupName="dataroominfra-rg"
synapseWorkspaceName="dataroominfra75dfecfebfwkspc"
userObjectIds=("bcb7b668-3054-418b-88c3-94cb8545996c" "043b1149-7368-4ba9-9810-27c04f166fbb" "fbb57ea3-3ea7-45af-9880-78b0788a2fa0" "296f9b4a-5d0c-402e-b94e-1019fd772e53" "26742fe6-f0e4-4b92-91a1-b92ab85bc0bf")

# Azure login
az login --service-principal --username $(yq eval '.client_tenant.client_id' ../values.yaml) --password $(yq eval '.client_tenant.client_secret' ../values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' ../values.yaml)

# Assign Reader role at the subscription level to all users
for userObjectId in "${userObjectIds[@]}"; do
    az role assignment create --role "Reader" --assignee-object-id $userObjectId --scope "/subscriptions/$subscriptionId"
done

# Assign Reader role at the Storage Account level to all users
for userObjectId in "${userObjectIds[@]}"; do
    az role assignment create --role "Reader" --assignee-object-id $userObjectId --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
done

# Get the list of containers in the storage account
containers=$(az storage container list --account-name $storageAccountName --query "[].name" -o tsv)

# Assign Storage Data Blob Reader role to all users for all containers
for container in $containers; do
    for userObjectId in "${userObjectIds[@]}"; do
        az role assignment create --role "Storage Blob Data Reader" --assignee-object-id $userObjectId --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName/blobServices/default/containers/$container"
    done
done

# Assign Synapse Contributor role to all users for the specified Synapse workspace
for userObjectId in "${userObjectIds[@]}"; do
    az synapse role assignment create --workspace-name $synapseWorkspaceName --role "Synapse Contributor" --assignee-object-id $userObjectId
done

# Assign Storage Contributor role to all the users for Synapse container
for userObjectId in "${userObjectIds[@]}"; do
    az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName/blobServices/default/containers/$synapseStorageContainer"
done
