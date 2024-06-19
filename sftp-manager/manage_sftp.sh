#!/bin/bash

# Default TTL in days
DEFAULT_TTL_DAYS=7

RESOURCE_GROUP=$(yq eval '.resource_group_name' values.yaml)
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Function to find the job number for a specific storage account and container
find_job_number() {
	local storage_account=$1
	local container_name=$2
	local job_number=""
	# List all jobs
	local job_list=$(atq)

	# Loop through each job to find the matching one
	while read -r job; do
		local job_id=$(echo $job | awk '{print $1}')
		local job_details=$(at -c $job_id)

		if echo "$job_details" | grep -q "$storage_account" && echo "$job_details" | grep -q "$container_name"; then
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
	az login --service-principal --username $(yq eval '.client_tenant.client_id' ../values.yaml) --password $(yq eval '.client_tenant.client_secret' ../values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' ../values.yaml)

	# Enable SFTP
	az storage account update --default-action Allow --name $storage_account --resource-group $RESOURCE_GROUP --enable-sftp true

	echo "SFTP has been enabled for the storage account: $storage_account"
}

# Function to disable SFTP
disable_sftp() {
	local storage_account=$1

	# Authenticate to Azure (assuming you are using managed identity or a service principal)
	az login --service-principal --username $(yq eval '.client_tenant.client_id' ../values.yaml) --password $(yq eval '.client_tenant.client_secret' ../values.yaml) --tenant $(yq eval '.client_tenant.tenant_id' ../values.yaml)

	# Disable SFTP
	az storage account update --default-action Allow --name $storage_account --resource-group $RESOURCE_GROUP --enable-sftp false

	echo "SFTP has been disabled for the storage account: $storage_account"
}

# Function to schedule the SFTP disable task based on TTL
schedule_disable_sftp_task() {
	local ttl_days=$1
	local storage_account=$2
	local container_name=$3

	# Calculate the disable date and time
	local disable_date_time=$(date -d "+$ttl_days days" "+%Y-%m-%d %H:%M:%S")
	local disable_date=$(date -d "$disable_date_time" "+%Y-%m-%d")
	local disable_hour=$(date -d "$disable_date_time" "+%H")
	local disable_minute=$(date -d "$disable_date_time" "+%M")

	# Schedule the disable task
	echo "$SCRIPT_PATH $storage_account $container_name" disable | at ${disable_hour}:${disable_minute} ${disable_date}

	echo "SFTP disable task scheduled for $storage_account at $disable_date_time"
}

# Function to update the SFTP schedule
update_sftp_schedule() {
	local storage_account=$1
	local container_name=$2
	local ttl_days=${3:-$DEFAULT_TTL_DAYS}
	local job_number=""

	# Find the existing job number
	local job_number=$(find_job_number $storage_account $container_name)
	echo "Job number $job_number"

	# If no existing job found, enable SFTP
	if [ -z "$job_number" ]; then
		echo "No existing job found for $storage_account and $container_name, enabling SFTP..."
		enable_sftp $storage_account
	else
		# Remove the existing job if found
		atrm $job_number
		echo "Removed existing job number: $job_number"
	fi

	# Schedule the disable task based on TTL
	schedule_disable_sftp_task $ttl_days $storage_account $container_name
}

# Function to print usage
print_usage() {
	echo "Usage: $0 <storage_account_name> <container_name> <enable|disable> [ttl_days]"
	echo "Example:"
	echo "  $0 <storage_account_name> <container_name> enable 7"
	echo "  $0 <storage_account_name> <container_name> disable"
}

# Function to validate input parameters
validate_input() {
	if [ -z "$STORAGE_ACCOUNT_NAME" ] || [ -z "$CONTAINER_NAME" ] || [ -z "$ACTION" ]; then
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
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
	echo "Error: Incorrect number of arguments."
	print_usage
	exit 1
fi

STORAGE_ACCOUNT_NAME=$1
CONTAINER_NAME=$2
ACTION=$3
TTL_DAYS=${4:-$DEFAULT_TTL_DAYS}

# Validate input parameters
validate_input

# Perform the action
if [ "$ACTION" == "enable" ]; then
	update_sftp_schedule $STORAGE_ACCOUNT_NAME $CONTAINER_NAME $TTL_DAYS
elif [ "$ACTION" == "disable" ]; then
	disable_sftp $STORAGE_ACCOUNT_NAME
else
	echo "Invalid action: $ACTION. Use 'enable' or 'disable'."
	exit 1
fi

# Logout from azure
az logout