#!/usr/bin/env bash

echo "Step 1: Destroy Infrastructure"
az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)

echo "Step 1: Destroy Resource group"
az group delete -n phonepeinfra-rg
az group delete -n terraform

echo "Step 3: Create Terraform Backend"