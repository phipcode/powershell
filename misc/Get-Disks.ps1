<#
.SYNOPSIS
    This script retrieves information about unattached disks from multiple Azure subscriptions and exports the results to a CSV file.

.DESCRIPTION
    This script queries multiple Azure subscriptions to identify unattached disks. It retrieves 
    information such as subscription details, disk properties (name, size, state, location), associated owners, 
    and resource group. The script then converts the disk tags into a string representation. 
    The collected information is stored in an array and exported to a CSV file named "UnattachedDisks.csv". 
    A confirmation message is displayed upon successful completion.

.NOTES
    Author: Phi Pham
    Date:   June 8, 2023

.LINK
   

#>

# Retrieve all subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.Name -notlike "*Azure*" -and $_.State -eq "Enabled" }

# Create an array to store the results
$results = @()

#Create empty string for resoure tag hashtable conversion
$resourceTagString = ""

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -Subscription $subscription.Id

    # Retrieve all disks in the subscription
    $disks = Get-AzDisk

    $subscriptionOwners = Get-AzRoleAssignment -RoleDefinitionName "Owner" -Scope "/subscriptions/$($subscription.Id)" | Select-Object -ExpandProperty DisplayName


    # Filter unattached disks
    $unattachedDisks = $disks | Where-Object { -not $_.ManagedBy }

    # Iterate through the unattached disks and retrieve the required information
    foreach ($disk in $unattachedDisks) {
        $subscriptionName = $subscription.Name
        $subscriptionOwnersList = $subscriptionOwners -join ";"
        $resourceGroupName = $disk.ResourceGroupName
        $diskName = $disk.Name
        $diskSize = $disk.DiskSizeGB
        $diskState = $disk.DiskState
        $location = $disk.Location

        # Convert tags to a string representation
        $Tags = $disk.Tags
        
        #Loop through has table for tags and append string
        if ($Tags -ne $null) {
            $tags.GetEnumerator() | % { $resourceTagString += $_.Key + ":" + $_.Value + ";" 
        }

        }
        else {

            $TagsAsString = "NULL"
        }

        $result = [PSCustomObject]@{
            Subscription = $subscriptionName
            Owners = $subscriptionOwnersList
            ResourceGroup = $resourceGroupName
            Tags = $resourceTagString
            DiskName = $diskName
            DiskSizeGB = $diskSize
            DiskState = $diskState
            Location = $location
        }

        $results += $result
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "UnattachedDisks.csv" -NoTypeInformation

Write-Host "Unattached disks exported to UnattachedDisks.csv"
