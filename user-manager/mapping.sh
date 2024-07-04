#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the values from the relative path
ROOT_VALUES="$SCRIPT_DIR/../values.yaml"
LOCAL_VALUES="$SCRIPT_DIR/values.yaml"

# Define variables
subscriptionId=$(yq eval '.subscription_id' "$LOCAL_VALUES")
synapseWorkspaceName=$(yq eval '.synapse_workspace_name' "$LOCAL_VALUES")
synapseStorageContainerId=$(yq eval '.synapse_storage_container_id' "$LOCAL_VALUES")
resourceGroupName=$(yq eval '.resource_group_name' "$LOCAL_VALUES")

first_party_account_id=$(yq eval '.first_party_details.account_id' "$LOCAL_VALUES")
first_party_public_container_id=$(yq eval '.first_party_details.public_container_id' "$LOCAL_VALUES")
first_party_private_container_id=$(yq eval '.first_party_details.private_container_id' "$LOCAL_VALUES")

partner_account_id=$(yq eval '.partner_details.account_id' "$LOCAL_VALUES")
partner_public_container_id=$(yq eval '.partner_details.public_container_id' "$LOCAL_VALUES")
partner_private_container_id=$(yq eval '.partner_details.private_container_id' "$LOCAL_VALUES")


terraform_output=$(cat terraform_output.json)
first_party_users=("5da0c63d-0b57-42ba-8624-3e1b10f620e2" "f4794ad8-8594-47d4-b52d-daa3ee76d88f" "629b6b44-ecaa-4b63-ab32-cedee9226588" "8454a249-193b-4d91-8dda-36336f33086f" "3b1e4a69-d67d-4236-9f7d-5dc11aa21af0" "2a2d4390-6105-4247-b30f-b4124c0b4fd7" "c42cd331-1e18-4454-862f-f7f9c87e07a2")
partner_users=()

# Combine the two arrays into one array
allUsers=("${first_party_users[@]}" "${partner_users[@]}")

# Azure login
az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")

echo "Assign Reader role at the subscription level to all users"
for userObjectId in "${allUsers[@]}"; do
    az role assignment create --role "Reader" --assignee-object-id $userObjectId --scope "/subscriptions/$subscriptionId"
done

echo "Assign Reader role at the Storage Account level to all users"
for accountId in "$first_party_account_id" "$partner_account_id"; do
    for userObjectId in "${allUsers[@]}"; do
        az role assignment create --role "Reader" --assignee-object-id $userObjectId --scope $accountId
    done
done

echo "Assign Storage Data Blob Reader role to all users for public containers"
for containerId in "$first_party_public_container_id" "$partner_public_container_id"; do
    for userObjectId in "${allUsers[@]}"; do
        az role assignment create --role "Storage Blob Data Reader" --assignee-object-id $userObjectId --scope $containerId
    done
done

echo "Assign Storage Blob Contributor role to respective users"
for containerId in "$first_party_public_container_id" "$first_party_private_container_id"; do
    for userObjectId in "${first_party_users[@]}"; do
        az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope $containerId
    done
done

for containerId in "$partner_public_container_id" "$partner_private_container_id"; do
    for userObjectId in "${partner_users[@]}"; do
        az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope $containerId
    done
done


echo "Assign Synapse Contributor role to all users for the Synapse workspace"
for userObjectId in "${allUsers[@]}"; do
    az synapse role assignment create --workspace-name $synapseWorkspaceName --role "Synapse Contributor" --assignee-object-id $userObjectId
done

echo "Assign Storage Contributor role to all the users for Synapse container"
for userObjectId in "${userObjectIds[@]}"; do
    az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userObjectId --scope $synapseStorageContainerId
done

az logout
