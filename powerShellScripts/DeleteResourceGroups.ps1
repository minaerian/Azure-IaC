param (
    [string]$subscriptionId,
    [string]$iac_env,
    [string]$location_suffix
)

# Delete Resource Groups for non-main branch
Set-AzContext -SubscriptionId $subscriptionId

# Define the resource groups to delete
$resourceGroupNames = @(
    "platform-ss-rg-${iac_env}-${location_suffix}".ToLower(), 
    "platform-identity-rg-${iac_env}-${location_suffix}".ToLower(),
    "platform-meraki-rg-${iac_env}-${location_suffix}".ToLower()
)

foreach ($rgName in $resourceGroupNames) {
    try {
        $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
        if ($rg) {
            # Delete the resource group
            Remove-AzResourceGroup -Name $rgName -Force
            Write-Output "Deleted resource group $rgName"
        } else {
            Write-Output "Resource group $rgName not found"
        }
    } catch {
        Write-Output "Error deleting resource group ${rgName}: $($_.Exception.Message)"
    }
}