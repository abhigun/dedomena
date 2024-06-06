# Define variables
subscriptionId="3de09913-013c-4995-9eee-10a4be77812b"
storageAccountName="demosftpa777617629"
resourceGroupName="dataroominfra-rg"
synapseWorkspaceName="dataroominfrac51b01c65bwkspc"
userObjectIds=("cee11b50-813e-4a7b-af09-63ae85e89549" "2d13e6fe-da05-4180-b9ba-ab0669b4e92c" "483a442a-de3e-4000-a74c-d380b3ebd4f5" "1746dadd-ead3-4463-85b6-806d4b5bcf82" "53f4a04d-5abd-4061-aed2-df4c7a583dec" "7f6cc15f-3005-46a9-904e-80dac80d9eb4")

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

# Support for adding Data contributor role on all user objectIds & synapse workspace objectId to the synapse inbuilt container 
