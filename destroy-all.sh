#!/bin/bash

# Set the base directory to the root of your project
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to run destroy.sh in a specified subfolder
run_destroy() {
  SUBFOLDER=$1
  echo "Running destroy.sh in $SUBFOLDER..."
  cd "$BASE_DIR/$SUBFOLDER"
  if [ -f "destroy.sh" ]; then
    chmod +x destroy.sh
    ./destroy.sh
  else
    echo "No destroy.sh script found in $SUBFOLDER."
  fi
  cd "$BASE_DIR"
}

# Run destroy.sh in each subfolder
run_destroy "user-manager"
run_destroy "sftp-manager"
run_destroy "infra"

echo "All destroy scripts executed."