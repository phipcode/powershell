<#
.SYNOPSIS
This PowerShell script updates the expiry date of all secrets stored in a specified Azure Key Vault.
It sets a new expiry date that is calculated to be two years from the current date. 
The script first sets the subscription context using the provided subscription ID. 
Then, it retrieves all the secrets from the specified Key Vault using the provided Key Vault name. 
Finally, it iterates through each secret and updates its expiry date to the newly calculated date,
notifying the user about the successful updates and logging any encountered errors.

.DESCRIPTION
The script performs the following steps:
1. Sets the subscription ID, Key Vault name, and the new expiry date (two years from the current date).
2. Sets the subscription context using Set-AzContext with the provided subscription ID.
3. Gets all secrets from the specified Key Vault using Get-AzKeyVaultSecret.
4. Loops through each secret and sets the expiry date to the newly calculated date using Set-AzKeyVaultSecretAttribute.
5. Outputs the successful updates with the secret names.
6. Logs any encountered errors during the update process.

.PARAMETER subscriptionId
The Azure subscription ID where the Key Vault resides.

.PARAMETER keyVaultName
The name of the Azure Key Vault containing the secrets to be updated.

.NOTES
Author: [Phi Pham]
Date: [07/08/23]
Version: 1.0

.LINK
[GitHub Repository URL or any other relevant link]

.EXAMPLE
.\UpdateKeyVaultSecretExpiry.ps1 -subscriptionId "a5ca5e86-3b6f-44b8-a115-d4061ec25089" -keyVaultName "test-delete-me"
Runs the script to update the expiry date of secrets in the specified Key Vault.

#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Azure Subscription ID")]
    [string]$subscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Azure Key Vault Name")]
    [string]$keyVaultName
)

# Set the subscription context
try {
    Set-AzContext -Subscription $subscriptionId -ErrorAction Stop
}
catch {
    Write-Error "Failed to set the subscription context to $subscriptionId. Error: $_"
    return
}

# Get all secrets in the Specified KeyVault
try {
    $secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName -ErrorAction Stop
}
catch {
    Write-Error "Failed to get secrets from Key Vault $keyVaultName. Error: $_"
    return
}

# Calculate the new expiry date (set to expire in 2 years from the current date)
$newExpiryDate = (Get-Date).AddYears(2)

# Loop through each secret and set the expiry date
foreach ($secret in $secrets) {
    try {
        Set-AzKeyVaultSecretAttribute -VaultName $keyVaultName -Name $secret.Name -Expires $newExpiryDate -ErrorAction Stop
        Write-Output "Updated expiry date for secret $($secret.Name)"
    }
    catch {
        Write-Error "Failed to update secret $($secret.Name). Error: $_"
    }
}