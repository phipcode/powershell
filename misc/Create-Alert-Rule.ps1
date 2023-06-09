<#
.SYNOPSIS
    This script creates an activity log alert in Azure subscriptions and resource groups based on predefined settings.

.DESCRIPTION
    This script creates an activity log alert in Azure subscriptions and resource groups based on specific settings provided. 
    It uses a predefined hashtable called $subscriptionResourceGroups to map subscription IDs to their respective resource group names. 
    The script iterates through each subscription and sets the current subscription context. 
    It then retrieves the corresponding resource group name from the hashtable and uses it to create an activity log alert in the subscription 
    and resource group using the Azure CLI (az). The script loops through all the subscription IDs and performs the same action for each one.

.NOTES
    Author: Phi Pham
    Date:   June 8, 2023

.LINK
    Any relevant links or references.

#>
$subscriptionResourceGroups = @{

    "123456-cedb-4ae4-b809-1235566" = "NSWDoE_Networking_Alerts_MGMT_RG" # DoE IS Networking - Exempt
}

$alertName = "Create-Update-NSG-Rule-Alert"
$description = "Alert triggered by Create/Update Nsg rule Events"
$actionGroupResourceId = "/subscriptions/12312312-873a-4d98-955a-fdfgd23112f/resourceGroups/NSWDoE_IS_CloudOps_RG/providers/microsoft.insights/actiongroups/CloudOps_AG"
$condition = "category=Administrative and operationName=Microsoft.Network/networkSecurityGroups/securityRules/write"

foreach ($subscriptionId in $subscriptionResourceGroups.Keys) {
    # Set the current subscription context
    az account set --subscription $subscriptionId

    # Get the resource group name for the current subscription
    $resourceGroupName = $subscriptionResourceGroups[$subscriptionId]

    # Create the activity log alert for the current subscription and resource group
    $createAlertCommand = "az monitor activity-log alert create --name $alertName --description `"$description`" --resource-group `"$resourceGroupName`" --scope `/subscriptions/$subscriptionId` --action-group `"$actionGroupResourceId`" --condition '$condition'"
    Invoke-Expression $createAlertCommand
}

#Operations 
#Microsoft.Network/networkSecurityGroups/securityRules/delete"  - Delete NSG Rule
#Microsoft.Network/networkSecurityGroups/delete -  Delete NSG
#Microsoft.Sql/servers/firewallRules/write SQL Firewall 
#Microsoft.Network/networkSecurityGroups/write - Create/Update NSG
#Microsoft.Network/networkSecurityGroups/securityRules/write - Create/Update NSG Rule