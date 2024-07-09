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

#!/bin/bash

# Set the base directory to the root of your project
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Extract variables using the absolute path to values.yaml
export ARM_CLIENT_ID="$(yq eval '.client_tenant.client_id' $BASE_DIR/values.yaml)"
export ARM_CLIENT_SECRET="$(yq eval '.client_tenant.client_secret' $BASE_DIR/values.yaml)"
export ARM_SUBSCRIPTION_ID="$(yq eval '.client_tenant.subscription_id' $BASE_DIR/values.yaml)"
export ARM_TENANT_ID="$(yq eval '.client_tenant.tenant_id' $BASE_DIR/values.yaml)"

# Log in to Azure using the extracted credentials
az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Destroy the Terraform-managed infrastructure
echo "Destroying Terraform-managed infrastructure in $(basename $(pwd))..."
terraform destroy -auto-approve

# Destroy the Terraform backend resource group
echo "Destroying Terraform backend resource group..."
az group delete -n terraform --yes --no-wait

# Log out from Azure
az logout

echo "Destruction complete for $(basename $(pwd))."