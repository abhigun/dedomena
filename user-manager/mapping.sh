# Define variables
subscriptionId=$(yq eval '.subscription_id' ./values.yaml)
synapseWorkspaceName=$(yq eval '.synapse_workspace_name' ./values.yaml)
synapseStorageContainerId=$(yq eval '.synapse_storage_container' ./values.yaml)
resourceGroupName=$(yq eval '.resource_group_name' ./values.yaml)

first_party_account_id=$(yq eval '.first_party_details.account_id' ./values.yaml)
first_party_public_container_id=$(yq eval '.first_party_details.public_container_id' ./values.yaml)
first_party_private_container_id=$(yq eval '.first_party_details.private_container_id' ./values.yaml)

partner_account_id=$(yq eval '.partner_details.account_id' ./values.yaml)
partner_public_container_id=$(yq eval '.partner_details.public_container_id' ./values.yaml)
partner_private_container_id=$(yq eval '.partner_details.first_party_private_container_id' ./values.yaml)


terraform_output=$(cat terraform_output.json)
first_party_users=($(echo "$terraform_output" | jq -r '.first_party_ad_users.value[] | .object_id'))
partner_users=($(echo "$terraform_output" | jq -r '.partner_ad_users.value[] | .object_id'))

# Combine the two arrays into one array
allUsers=("${first_party_users[@]}" "${partner_users[@]}")

# Azure login
az login --service-principal --username $(yq eval '.client_tenant.client_id' ../values.yaml) --password $(yq eval '.client_tenant.client_secret' ../values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' ../values.yaml)

# Assign Reader role at the subscription level to all users
for userObjectId in "${allUsers[@]}"; do
    az role assignment create --role "Reader" --assignee-object-id $userObjectId --scope "/subscriptions/$subscriptionId"
done

# Assign Reader role at the Storage Account level to all users
for accountId in "$first_party_account_id" "$partner_account_id"; do
    for userObjectId in "${allUsers[@]}"; do
        az role assignment create --role "Reader" --assignee-object-id $userObjectId --scope $accountId
    done
done

# Assign Storage Data Blob Reader role to all users for public containers
for containerId in "$first_party_public_container_id" "$partner_public_container_id"; do
    for userObjectId in "${allUsers[@]}"; do
        az role assignment create --role "Storage Blob Data Reader" --assignee-object-id $userObjectId --scope $containerId
    done
done

#Assign Storage Blob Contributor role to respective users 
for containerId in "$first_party_public_container_id" "$first_party_private_container_id"; do
    for userObjectId in "${firstPartyUsers[@]}"; do
        az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope $containerId
    done
done

for containerId in "$partner_public_container_id" "$partner_private_container_id"; do
    for userObjectId in "${partnerUsers[@]}"; do
        az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope $containerId
    done
done


# Assign Synapse Contributor role to all users for the Synapse workspace
for userObjectId in "${allUsers[@]}"; do
    az synapse role assignment create --workspace-name $synapseWorkspaceName --role "Synapse Contributor" --assignee-object-id $userObjectId
done

# Assign Storage Contributor role to all the users for Synapse container
for userObjectId in "${userObjectIds[@]}"; do
    az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope $synapseStorageContainerId
done

az logout
