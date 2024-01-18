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

export ARM_CLIENT_ID="$(yq eval '.client_tenant.client_id' values.yaml)"
export ARM_CLIENT_SECRET="$(yq eval '.client_tenant.client_secret' values.yaml)"
export ARM_SUBSCRIPTION_ID="$(yq eval '.client_tenant.subscription_id' values.yaml)"
export ARM_TENANT_ID="$(yq eval '.client_tenant.tenant_id' values.yaml)"


az login --service-principal --username $(yq eval '.client_tenant.client_id' values.yaml) --password $(yq eval '.client_tenant.client_secret' values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' values.yaml)
echo "Step 1: Destroy Infrastructure"
terraform destroy

echo "Step 2: Destroying terraform backend resource group"
az group delete -n terraform