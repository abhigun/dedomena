#!/bin/bash

# Default TTL in days
DEFAULT_TTL_DAYS=7
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the values from the relative path
ROOT_VALUES="$SCRIPT_DIR/../values.yaml"
LOCAL_VALUES="$SCRIPT_DIR/values.yaml"

RESOURCE_GROUP=$(yq eval '.resource_group_name' "$LOCAL_VALUES")
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

# Function to find the job number for a specific storage account
find_job_number() {
	local storage_account=$1
	local job_number=""
	# List all jobs
	local job_list=$(atq)

	# Loop through each job to find the matching one
	while read -r job; do
		local job_id=$(echo $job | awk '{print $1}')
		local job_details=$(at -c $job_id)

		if echo "$job_details" | grep -q "$storage_account"; then
			job_number=$job_id
			break
		fi
	done <<< "$job_list"

	echo "$job_number"
}

# Function to enable SFTP
enable_sftp() {
	local storage_account=$1

	# Authenticate to Azure
	az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")

	# Enable SFTP
	az storage account update --default-action Allow --name $storage_account --resource-group $RESOURCE_GROUP --enable-sftp true

	echo "SFTP has been enabled for the storage account: $storage_account"
}

# Function to disable SFTP
disable_sftp() {
	local storage_account=$1

	# Authenticate to Azure (assuming you are using managed identity or a service principal)
	az login --service-principal --username $(yq eval '.client_tenant.client_id' "$ROOT_VALUES") --password $(yq eval '.client_tenant.client_secret' "$ROOT_VALUES") --tenant $(yq eval '.client_tenant.tenant_id' "$ROOT_VALUES")

	# Disable SFTP
	az storage account update --default-action Allow --name $storage_account --resource-group $RESOURCE_GROUP --enable-sftp false

	echo "SFTP has been disabled for the storage account: $storage_account"
}

# Function to schedule the SFTP disable task based on TTL
schedule_disable_sftp_task() {
	local ttl_days=$1
	local storage_account=$2

	# Calculate the disable date and time
	local disable_date_time=$(date -d "+$ttl_days days" "+%Y-%m-%d %H:%M:%S")
	local disable_date=$(date -d "$disable_date_time" "+%Y-%m-%d")
	local disable_hour=$(date -d "$disable_date_time" "+%H")
	local disable_minute=$(date -d "$disable_date_time" "+%M")

	# Schedule the disable task
	echo "$SCRIPT_PATH $storage_account disable" | at ${disable_hour}:${disable_minute} ${disable_date}

	echo "SFTP disable task scheduled for $storage_account at $disable_date_time"
}

# Function to update the SFTP schedule
update_sftp_schedule() {
	local storage_account=$1
	local ttl_days=${2:-$DEFAULT_TTL_DAYS}
	local job_number=""

	# Find the existing job number
	local job_number=$(find_job_number $storage_account)
	echo "Job number $job_number"

	# If no existing job found, enable SFTP
	if [ -z "$job_number" ]; then
		echo "No existing job found for $storage_account, enabling SFTP..."
	else
		# Remove the existing job if found
		atrm $job_number
		echo "Removed existing job number: $job_number"
	fi
	enable_sftp $storage_account
	# Schedule the disable task based on TTL
	schedule_disable_sftp_task $ttl_days $storage_account
}

# Function to print usage
print_usage() {
	echo "Usage: $0 <storage_account_name> <enable|disable> [ttl_days]"
	echo "Example:"
	echo "  $0 <storage_account_name> enable 7"
	echo "  $0 <storage_account_name> disable"
}

# Function to validate input parameters
validate_input() {
	if [ -z "$STORAGE_ACCOUNT_NAME" ] || [ -z "$ACTION" ]; then
		echo "Error: Missing required arguments."
		print_usage
		exit 1
	fi

	if [ "$ACTION" != "enable" ] && [ "$ACTION" != "disable" ]; then
		echo "Error: Invalid action '$ACTION'. Use 'enable' or 'disable'."
		print_usage
		exit 1
	fi

	if [ "$ACTION" == "enable" ] && [ -n "$TTL_DAYS" ]; then
		if ! [[ "$TTL_DAYS" =~ ^[0-9]+$ ]]; then
			echo "Error: TTL days must be a positive integer."
			print_usage
			exit 1
		fi
	fi
}

# Main script to handle input and call appropriate functions
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
	echo "Error: Incorrect number of arguments."
	print_usage
	exit 1
fi

STORAGE_ACCOUNT_NAME=$1
ACTION=$2
TTL_DAYS=${3:-$DEFAULT_TTL_DAYS}

# Validate input parameters
validate_input

# Perform the action
if [ "$ACTION" == "enable" ]; then
	update_sftp_schedule $STORAGE_ACCOUNT_NAME $TTL_DAYS
elif [ "$ACTION" == "disable" ]; then
	disable_sftp $STORAGE_ACCOUNT_NAME
else
	echo "Invalid action: $ACTION. Use 'enable' or 'disable'."
	exit 1
fi

# Logout from azure
az logout