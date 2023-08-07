<#
.SYNOPSIS
This PowerShell script retrieves information about Network Security Groups (NSGs) in Azure subscriptions
 and identifies NSGs that have a specific address prefix in their rules. The script outputs the results
  to both the console in a formatted table and to a CSV file named "NetworkAddresses1.csv."

.DESCRIPTION
This PowerShell script retrieves information about Network Security Groups (NSGs) in Azure subscriptions 
and identifies NSGs that have a specific address prefix ("198.18.0.0/16") in their rules. 
The script then displays the matching results in a formatted table and exports the information 
to a CSV file named "NetworkAddresses1.csv."

.NOTES
Author: [Phi Pham]
Date: [07/08/2023]
Version: 1.0

.LINK


.EXAMPLE
.\MyNetworkSecurityGroupsScript.ps1
Runs the script to retrieve information about NSGs and export the results to a CSV file.

#>

# Retrieve all subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.Name -notlike "*Azure*" -and $_.State -eq "Enabled" }

# Initialize an array to store the matching results
$matchingResults = @()

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -Subscription $subscription

    # Get all NSGs
    $nsgs = Get-AzNetworkSecurityGroup

    # Define the address to find
    $addressToFind = "198.18.0.0/16"

    # Iterate through each NSG
    foreach ($nsg in $nsgs) {
        # Initialize an array to store the affected addresses for this NSG
        $affectedAddresses = @()

        # Get all NSG rules for the current NSG
        $rules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg

        # Check if the specified address exists in any of the NSG rules
        foreach ($rule in $rules) {
            if ($rule.SourceAddressPrefix -eq $addressToFind) {
                # Add the affected address to the array
                $affectedAddresses += $rule.SourceAddressPrefix
            }
        }

        if ($affectedAddresses.Count -gt 0) {
            # Get the NSG details and add them to the matching results array
            $result = [PSCustomObject]@{
                SubscriptionId    = $nsg.Id.Split('/')[2]
                ResourceGroup     = $nsg.ResourceGroupName
                NSGName           = $nsg.Name
                NSGRuleName       = ($rules | Where-Object { $_.SourceAddressPrefix -eq $addressToFind }).Name
                AffectedAddresses = $affectedAddresses -join ', '
            }
            $matchingResults += $result
        }
    }
}

# Display the matching results in a table
$matchingResults | Format-Table -AutoSize

# Export the results to a CSV file
$matchingResults | Export-Csv -Path "NetworkAddresses1.csv" -NoTypeInformation
