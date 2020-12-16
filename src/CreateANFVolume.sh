#!/bin/bash
set -euo pipefail

# Mandatory variables for ANF resources
# Change variables according to your environment 
SUBSCRIPTION_ID=""
LOCATION="WestUS"
RESOURCEGROUP_NAME="My-rg"
VNET_NAME="netapp-vnet"
SUBNET_NAME="netapp-subnet"
NETAPP_ACCOUNT_NAME="netapptestaccount"
NETAPP_POOL_NAME="netapptestpool"
NETAPP_POOL_SIZE_TIB=4
NETAPP_VOLUME_NAME="netapptestvolume"
SERVICE_LEVEL="Standard"
NETAPP_VOLUME_SIZE_GIB=100
PROTOCOL_TYPE="NFSv4.1"
SHOULD_CLEANUP="false"

# Exit error code
ERR_ACCOUNT_NOT_FOUND=100

# Utils Functions
display_bash_header()
{
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo "Azure NetApp Files CLI NFS Sample  - Sample Bash script that creates Azure NetApp Files uses NFSv3 or NFSv4.1 protocol"
    echo "----------------------------------------------------------------------------------------------------------------------"
}

display_cleanup_header()
{
    echo "----------------------------------------"
    echo "Cleaning up Azure NetApp Files Resources"
    echo "----------------------------------------"
}

display_message()
{
    time=$(date +"%T")
    message="$time : $1"
    echo $message
}
# ANF create functions

# Create Azure NetApp Files Account
create_or_update_netapp_account()
{    
    local __resultvar=$1
    local _NEW_ACCOUNT_ID=""

    _NEW_ACCOUNT_ID=$(az netappfiles account create --resource-group $RESOURCEGROUP_NAME \
        --name $NETAPP_ACCOUNT_NAME \
        --location $LOCATION | jq ".id")

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'${_NEW_ACCOUNT_ID}'"
    else
        echo "${_NEW_ACCOUNT_ID}"
    fi
}


# Create Azure NetApp Files Capacity Pool
create_or_update_netapp_pool()
{
    local __resultvar=$1
    local _NEW_POOL_ID=""

    _NEW_POOL_ID=$(az netappfiles pool create --resource-group $RESOURCEGROUP_NAME \
        --account-name $NETAPP_ACCOUNT_NAME \
        --name $NETAPP_POOL_NAME \
        --location $LOCATION \
        --size $NETAPP_POOL_SIZE_TIB \
        --service-level $SERVICE_LEVEL | jq ".id")

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'${_NEW_POOL_ID}'"
    else
        echo "${_NEW_POOL_ID}"
    fi
}


# Create Azure NetApp Files Volume
create_or_update_netapp_volume()
{
    local __resultvar=$1
    local _NEW_VOLUME_ID=""

    _NEW_VOLUME_ID=$(az netappfiles volume create --resource-group $RESOURCEGROUP_NAME \
        --account-name $NETAPP_ACCOUNT_NAME \
        --file-path $NETAPP_VOLUME_NAME \
        --pool-name $NETAPP_POOL_NAME \
        --name $NETAPP_VOLUME_NAME \
        --location $LOCATION \
        --service-level $SERVICE_LEVEL \
        --usage-threshold $NETAPP_VOLUME_SIZE_GIB \
        --vnet $VNET_NAME \
        --subnet $SUBNET_NAME \
        --protocol-types $PROTOCOL_TYPE | jq ".id")

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'${_NEW_VOLUME_ID}'"
    else
        echo "${_NEW_VOLUME_ID}"
    fi      
}

# ANF cleanup functions

# Delete Azure NetApp Files Account
delete_netapp_account()
{
    az netappfiles account delete --resource-group $RESOURCEGROUP_NAME \
        --name $NETAPP_ACCOUNT_NAME    
}

# Delete Azure NetApp Files Capacity Pool
delete_netapp_pool()
{
    az netappfiles pool delete --resource-group $RESOURCEGROUP_NAME \
        --account-name $NETAPP_ACCOUNT_NAME \
        --name $NETAPP_POOL_NAME
    sleep 10    
}

# Delete Azure NetApp Files Volume
delete_netapp_volume()
{
    az netappfiles volume delete --resource-group $RESOURCEGROUP_NAME \
        --account-name $NETAPP_ACCOUNT_NAME \
        --pool-name $NETAPP_POOL_NAME \
        --name $NETAPP_VOLUME_NAME
    sleep 10
}

#Script Start
#Display Header
display_bash_header

# Login and Authenticate to Azure
display_message "Authenticating into Azure"
az login

# Set the target subscription 
display_message "setting up the target subscription"
az account set --subscription $SUBSCRIPTION_ID

display_message "Creating Azure NetApp Files Account ..."
{    
    NEW_ACCOUNT_ID="";create_or_update_netapp_account NEW_ACCOUNT_ID
    display_message "Azure NetApp Files Account was created successfully: $NEW_ACCOUNT_ID"
} || {
    display_message "Failed to create Azure NetApp Files Account"
    exit 1
}

display_message "Creating Azure NetApp Files Pool ..."
{
    NEW_POOL_ID="";create_or_update_netapp_pool NEW_POOL_ID
    display_message "Azure NetApp Files pool was created successfully: $NEW_POOL_ID"
} || {
    display_message "Failed to create Azure NetApp Files pool"
    exit 1
}

display_message "Creating Azure NetApp Files Volume..."
{
    NEW_VOLUME_ID="";create_or_update_netapp_volume NEW_VOLUME_ID
    display_message "Azure NetApp Files volume was created successfully: $NEW_VOLUME_ID"
} || {
    display_message "Failed to create Azure NetApp Files volume"
    exit 1
}

# Clean up resources
if [[ "$SHOULD_CLEANUP" == true ]]; then
    #Display cleanup header
    display_cleanup_header

    # Delete Volume
    display_message "Deleting Azure NetApp Files Volume..."
    {
        delete_netapp_volume
        display_message "Azure NetApp Files volume was deleted successfully"
    } || {
        display_message "Failed to delete Azure NetApp Files volume"
        exit 1
    }

    #Delete Capacity Pool
    display_message "Deleting Azure NetApp Files Pool ..."
    {
        delete_netapp_pool
        display_message "Azure NetApp Files pool was deleted successfully"
    } || {
        display_message "Failed to delete Azure NetApp Files pool"
        exit 1
    }

    #Delete Account
    display_message "Deleting Azure NetApp Files Account ..."
    {
        delete_netapp_account
        display_message "Azure NetApp Files Account was deleted successfully"
    } || {
        display_message "Failed to delete Azure NetApp Files Account"
        exit 1
    }
fi