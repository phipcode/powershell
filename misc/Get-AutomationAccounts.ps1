<#
.SYNOPSIS
    This script retrieves specific variables from Azure Automation accounts across multiple subscriptions 
    based on a provided CSV file and exports the matching results to a CSV file.

.DESCRIPTION
    This script queries multiple Azure subscriptions to find matching variables in Azure Automation accounts. 
    It loads a CSV file containing variable names and subscription names to compare against. 
    The script iterates through each subscription, retrieves the Automation accounts, and examines the variables within each account. 
    If a match is found between a variable name and subscription name in the loaded CSV file, the variable information,
    along with the associated Automation account, subscription, and resource group, is stored in an array.
    The matching results are then displayed as a table on the console and exported to a CSV file named "matchingResults.csv".

.NOTES
    Author: Phi Pham
    Date:   June 8, 2023

.EXAMPLE
    Example file for $variableNamesFile 
    VariableName	    SubscriptionName
    webappname	        Subscription Prod
    test_sb_string	    Subscription Non-Prod
    subscriptionid	    Subscription WAN
    resourcegroupname	Subscription WAN
    elasticjobconfig	Subscription Non-Prod
    elasticjobconfig	Subscription Prod
    detdbaconfig	    SubscriptionNon-Prod
    detdbaconfig	    Subscription Prod


.LINK
    Any relevant links or references.

#>
# Retrieve all subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.Name -notlike "*Azure*" -and $_.State -eq "Enabled" }

# Load the CSV file containing variable names
$variableNamesFile = Import-Csv -Path 'C:\Users\ppham\repo\doe\automationAccounts.csv'

# Create an array to store the results
$matchingResults = @()

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -Subscription $subscription.Id

    # Retrieve the Automation accounts for the current subscription
    $automationAccounts = Get-AzAutomationAccount

    foreach ($account in $automationAccounts) {
        # Get the subscription name
        $subscriptionName = (Get-AzContext).Subscription.Name

        # Get all variables for the current Automation account
        $variables = Get-AzAutomationVariable -ResourceGroupName $account.ResourceGroupName -AutomationAccountName $account.AutomationAccountName

        # Iterate through each variable
        foreach ($variable in $variables) {
            # Check if the variable name and subscription name exist in the variable names file
            $match = $variableNamesFile | Where-Object { $_.VariableName -eq $variable.Name -and $_.SubscriptionName -eq $subscriptionName }

            if ($match) {
                # Extract the variable value
                $variableValue = $variable.Value

                # Create a custom object with the matching result
                $matchingResult = [PSCustomObject]@{
                    AutomationAccount = $account.AutomationAccountName
                    VariableName      = $variable.Name
                    VariableValue     = $variableValue
                    Subscription      = $subscriptionName
                    ResourceGroup     = $account.ResourceGroupName
                }

                # Add the matching result to the array
                $matchingResults += $matchingResult
            }
        }
    }
}

# Display the matching results as a table on the console
$matchingResults | Format-Table

# Export the matching results to a new CSV file
$matchingResults | Export-Csv -Path 'C:\Users\ppham\repo\doe\matchingResults.csv' -NoTypeInformation

