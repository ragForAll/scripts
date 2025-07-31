#!/bin/bash

# Exit immediately if any command fails.
# This ensures that if a command within this script fails (e.g., a sub-script exits with non-zero),
# this master script will also terminate.



set -e

# --- Determine Script Directory ---
# SCRIPT_DIR is the directory where this master script is located.
# This is crucial for correctly referencing other scripts and files relative to this one.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "🚀 Starting full deployment orchestration..."
echo "Current script directory: $SCRIPT_DIR"

####################################
# Infrastructure Deployment        #
####################################
echo "Starting infrastructure deployment..."
# Execute the deploy.sh script.
# It runs in a sub-shell. If it exits with 1, this master script will also exit due to 'set -e'.
"$SCRIPT_DIR/../vm/scripts/deploy.sh"

echo "✅ Infrastructure deployment successful. Proceeding..."


####################################
# Extracting VM IP Address         #
####################################
echo "🛰️ Extracting VM IP address..."
# Source extractIP.sh. This is CRUCIAL because extractIP.sh EXPORTS the 'IP' variable.
# Sourcing ensures 'IP' becomes available in *this* master script's environment.
. "$SCRIPT_DIR/../vm/scripts/extractIP.sh" # Or 'source "$SCRIPT_DIR/../vm/scripts/extractIP.sh"'

# Validate if the IP variable was successfully set by extractIP.sh
# Note: 'set -e' might not catch if the sourced script *fails to set* a variable
# but doesn't explicitly 'exit 1'. So an explicit check is good.
if [ -z "$IP" ]; then
    echo "❌ Error: IP variable not set by extractIP.sh. Exiting."
    exit 1
fi
echo "✅ IP extraction successful: IP=$IP. Proceeding..."


######################################
# Write IP to Ansible Inventory File #
######################################
echo "📝 Writing IP to Ansible inventory file..."
# Execute ipWriter.sh. It runs in a sub-shell.
# It will use the 'IP' variable that was exported by extractIP.sh into this shell.
"$SCRIPT_DIR/../../provisioning/scripts/ipWriter.sh"

echo "✅ IP written successfully to Ansible inventory file. Proceeding..."


######################################
# Run Ansible Playbook to Deploy App #
######################################  
echo "⚙️ Running Ansible Playbook to deploy application..."
# Execute execute.sh (which in turn runs ansible-playbook).
# It runs in a sub-shell. It will use the 'IP' variable if needed (which it does via python script).
"$SCRIPT_DIR/../../provisioning/scripts/execute.sh"

echo "✅ Ansible playbook executed successfully. Application deployed. Proceeding..."


#######################
# Workflows Creations #
#######################
echo "💡 Creating workflows in n8n..."
# Execute workflowsCreation.sh. It runs in a sub-shell.
# It will use the 'IP' variable via its Python script.
"$SCRIPT_DIR/../../workflowsManager/scripts/workflowsCreation.sh"

echo "🎉 Workflows created successfully. Full process completed!"