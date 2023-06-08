<#
.SYNOPSIS
    This script retrieves the resource group name for a resource from a CSV file

.DESCRIPTION
    This script retrieves the resource group name for a resource. It imports a CSV file 
    which has 2 columns "resourceName" & "subscription". It loops through each row and 
    retrieves the resource grouyp name using the Azure PowerShell module. It then appends the resource group
    name to the CSV data. The updated data is then displayed on the console as a table and exported
    to a new CSV file.

.NOTES
    Author: Phi Pham
    Date:   June 8, 2023

.LINK
    Any relevant links or references.

#>

# Import the CSV file
$csv = Import-Csv -Path 'C:\Users\ppham\repo\doe\resources.csv'


# Initialize a variable to store the current subscription context
$currentSubscription = $null

# Create an array to store the results
$results = @()

# Loop through each row in the CSV
foreach ($row in $csv) {

    # Loop through each row in the CSV
    $resourceName = $row.resourceName
    $subscription = $row.subscription

    # Check if the current subscription context is different from the subscription in the row
    if ($currentSubscription -ne $subscription) {
        # Set the context for the subscription
        Set-AzContext -Subscription $subscription
        $currentSubscription = $subscription
    }

 
    #retieve the resource group name using az command
    $resourceGroup = (Get-AzResource -ResourceName $resourceName).ResourceGroupName

    # Convert the resourceGroup to a string if it's an array
    if ($resourceGroup -is [System.Object[]]) {
        $resourceGroup = $resourceGroup -join ","
    }

    #Append the resource group name to CSV
    $row | Add-Member -MemberType NoteProperty -Name 'resourceGroup' -Value $resourceGroup

    #Display the results on console
    $result = [PSCustomObject]@{
        ResourceName  = $resourceName
        Subscription  = $subscription
        ResourceGroup = $resourceGroup
    }

    #Add results to the array
    $results += $result
}


#Display the results as a table on the console
$results | Format-Table 

# Export the updated CSV
$results | Export-csv -Path 'C:\Users\ppham\repo\doe\CLOUDOPS-2648.csv' -NoTypeInformation


